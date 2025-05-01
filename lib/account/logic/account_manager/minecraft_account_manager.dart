import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart'
    show CachedNetworkImage;
import 'package:meta/meta.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../common/constants/microsoft_constants.dart';
import '../../../common/logic/app_logger.dart';
import '../../../common/logic/utils.dart';
import '../../data/account_storage/account_storage.dart';
import '../../data/microsoft_auth_api/auth_methods/microsoft_device_code_flow.dart';
import '../../data/microsoft_auth_api/microsoft_auth_api.dart';
import '../../data/microsoft_auth_api/microsoft_auth_exceptions.dart';
import '../../data/minecraft_account.dart';
import '../../data/minecraft_accounts.dart';
import '../../data/minecraft_api/minecraft_api.dart';
import '../../data/minecraft_api/minecraft_api_exceptions.dart';
import '../minecraft_skin_ext.dart';
import 'async_timer.dart';
import 'http_server_ext.dart';
import 'minecraft_account_manager_exceptions.dart';

// TODO: Separate Microsoft related logic into a new class, and probably have device code and auth code logic in two different classes?

class MinecraftAccountManager {
  MinecraftAccountManager({
    required this.microsoftAuthApi,
    required this.minecraftApi,
    required this.accountStorage,
  });

  final MicrosoftAuthApi microsoftAuthApi;
  final MinecraftApi minecraftApi;

  final AccountStorage accountStorage;

  Future<T> _transformExceptions<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on MicrosoftAuthException catch (e) {
      throw AccountManagerException.microsoftAuthApiException(e);
    } on MinecraftApiException catch (e) {
      throw AccountManagerException.minecraftApiException(e);
    } on AccountManagerException {
      rethrow;
    } on Exception catch (e, stackTrace) {
      throw AccountManagerException.unknown(e.toString(), stackTrace);
    }
  }

  // START: Auth code

  /// Minimal HTTP server for handling Microsoft's redirect in the auth code flow.
  /// Microsoft will redirect to this server with the auth code after the user logs in.
  @visibleForTesting
  HttpServer? httpServer;

  @visibleForTesting
  HttpServer get requireServer =>
      httpServer ??
      (throw StateError(
        'The server has not started yet which is required for the login using the auth code flow.',
      ));

  bool get isServerRunning => httpServer != null;

  Future<HttpServer> startServer() async {
    assert(
      !isServerRunning,
      'The Microsoft Auth Redirect server cannot be started if it is already running.',
    );
    httpServer = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      MicrosoftConstants.loginRedirectPort,
    );
    AppLogger.i('Starting Microsoft Auth Redirect server');
    return requireServer;
  }

  Future<void> stopServer() async {
    assert(
      isServerRunning,
      "The Microsoft Auth Redirect server cannot be stopped if it hasn't started yet.",
    );
    await requireServer.close();
    httpServer = null;
    AppLogger.i('Stopping Microsoft Auth Redirect server');
  }

  Future<bool> stopServerIfRunning() async {
    if (isServerRunning) {
      await stopServer();
      return true;
    }
    return false;
  }

  Future<AccountResult?> loginWithMicrosoftAuthCode({
    required void Function(
      MicrosoftAuthProgress newProgress, {

      /// Not null if [newProgress] is [MicrosoftAuthProgress.waitingForUserLogin]
      String? authCodeLoginUrl,
    })
    onProgressUpdate,
    // The page content is not hardcoded for localization.
    required AuthCodeSuccessLoginPageContent successLoginPageContent,
  }) => _transformExceptions(() async {
    final server = httpServer ?? await startServer();

    // Open the link
    final authCodeLoginUrl = microsoftAuthApi.userLoginUrlWithAuthCode();
    await launchUrl(Uri.parse(authCodeLoginUrl));

    onProgressUpdate(
      MicrosoftAuthProgress.waitingForUserLogin,
      authCodeLoginUrl: authCodeLoginUrl,
    );

    cancelDeviceCodePollingTimer();

    // Wait for the user response

    final request = await server.firstOrNull;
    if (request == null) {
      // The server was closed because the user didn't log in.
      // It automatically shuts down when the login dialog is closed.
      return null;
    }

    final code =
        request.uri.queryParameters[MicrosoftConstants
            .loginRedirectCodeQueryParamName];
    if (code == null) {
      await stopServer();
      throw AccountManagerException.missingAuthCode();
    }
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..write(buildAuthCodeSuccessPageHtml(successLoginPageContent));
    await request.response.close();
    await stopServer();

    onProgressUpdate(MicrosoftAuthProgress.exchangingAuthCode);

    final oauthTokenResponse = await microsoftAuthApi.exchangeAuthCodeForTokens(
      code,
    );

    return _commonLoginWithMicrosoft(
      oauthTokenResponse: oauthTokenResponse,
      onProgressUpdate: (newProgress) => onProgressUpdate(newProgress),
    );
  });

  // END: Auth code

  // START: Device code

  /// Timer that periodically checks the device code status during login.
  /// Set when [requestLoginWithMicrosoftDeviceCode] is called, and cleared
  /// after success or code expiration.
  @visibleForTesting
  AsyncTimer<MicrosoftDeviceCodeSuccess?>? deviceCodePollingTimer;

  bool get isDeviceCodePollingTimerActive =>
      deviceCodePollingTimer?.isActive ?? false;

  /// A flag is used to cancel the timer when [cancelDeviceCodePollingTimer] is
  /// called before [deviceCodePollingTimer] is initialized.
  /// Once [deviceCodePollingTimer] is initialized, this flag
  /// will be used inside the timer callback to cancel it.
  @visibleForTesting
  bool requestCancelDeviceCodePollingTimer = false;

  // Cancels the polling timer if active.
  // Returns whether the timer has been cancelled and was active.
  bool cancelDeviceCodePollingTimer([MicrosoftDeviceCodeSuccess? result]) {
    final isActive = isDeviceCodePollingTimerActive;
    deviceCodePollingTimer?.cancel(result);
    deviceCodePollingTimer = null;
    requestCancelDeviceCodePollingTimer = true;
    return isActive;
  }

  /// Requests a device code for login and keeps polling the device code status
  /// until the code expires or login is successful.
  ///
  /// Returns null when the device code has expired or the timer
  /// has been cancelled (e.g., dialog is closed).
  Future<(AccountResult?, DeviceCodeTimerCloseReason)>
  requestLoginWithMicrosoftDeviceCode({
    required void Function(MicrosoftAuthProgress newProgress) onProgressUpdate,
    required void Function(String deviceCode) onDeviceCodeAvailable,
  }) => _transformExceptions(() async {
    // NOTE: This flag is used to fix a race condition where the timer is requested
    // to be cancelled before it's started (i.e. set to not null) since the timer
    // starts after the future call finishes, during this time, the timer may
    // requested to be cancelled, when cancelling the timer, it will be set to null,
    // however if it hasn't set yet, it will later run when the request
    // device code future is finished. It's used inside the timer callback
    // so it will be cancelled when it should.
    //
    // IMPORTANT: Set this to false before awaiting future call since this issue
    // happens while awaiting it. Setting it to false after the await, will
    // not fix this race condition and the behavior is the same without this flag.
    // Not setting it to false at all, will cancel the timer on next run when it shouldn't.
    requestCancelDeviceCodePollingTimer = false;

    final deviceCodeResponse = await microsoftAuthApi.requestDeviceCode();
    final deviceCodeExpiresAt = expiresInToExpiresAt(
      deviceCodeResponse.expiresIn,
    );

    onDeviceCodeAvailable(deviceCodeResponse.userCode);
    onProgressUpdate(MicrosoftAuthProgress.waitingForUserLogin);

    var closeReason = DeviceCodeTimerCloseReason.normal;

    void cancelTimerOnExpiration() {
      closeReason = DeviceCodeTimerCloseReason.codeExpired;
      cancelDeviceCodePollingTimer();
    }

    deviceCodePollingTimer = AsyncTimer.periodic(
      Duration(
        seconds:
            deviceCodeResponse
                .interval, // This is probably 5 seconds but should not be hardcoded
      ),
      () async {
        if (requestCancelDeviceCodePollingTimer) {
          // Fixes an issue where the timer is requested to be canceled
          // before it has started, due to awaiting a future call. Which
          // will cause the timer to continue running.
          cancelDeviceCodePollingTimer();

          // After this call, _requestCancelDeviceCodePollingTimer is remain true
          // and will be set to false on the next run.
          return;
        }
        // Check if the device code has expired before making the API call
        final hasDeviceCodeExpired = deviceCodeExpiresAt.isBefore(
          DateTime.now(),
        );
        if (hasDeviceCodeExpired) {
          cancelTimerOnExpiration();
          return;
        }
        final checkDeviceCodeResult = await microsoftAuthApi
            .checkDeviceCodeStatus(deviceCodeResponse);
        switch (checkDeviceCodeResult) {
          case MicrosoftDeviceCodeSuccess():
            cancelDeviceCodePollingTimer(checkDeviceCodeResult);
          case MicrosoftDeviceCodeExpired():
            // The API indicates the device code has expired, which may happen
            // even though we check locally, handle it gracefully
            cancelTimerOnExpiration();
          case MicrosoftDeviceCodeAuthorizationPending():
            // User has not yet authenticated; continue polling
            break;
        }
      },
    );

    Future<void>.delayed(Duration(seconds: deviceCodeResponse.expiresIn), () {
      if (isDeviceCodePollingTimerActive) {
        // Fallback to ensure the timer is stopped and completer is completed
        // in case something goes wrong.

        cancelTimerOnExpiration();
      }
    });

    final deviceCodeSuccess = await deviceCodePollingTimer!.awaitTimer();

    assert(
      !isDeviceCodePollingTimerActive,
      'The device code check timer should be cancelled at this point, this is likely a bug.',
    );

    if (deviceCodePollingTimer != null) {
      AppLogger.w(
        'This is likely a bug, the timer should be closed at this point',
      );
      cancelDeviceCodePollingTimer();
    }

    // Response of exchanging the device code.
    final oauthTokenExchangeResponse = deviceCodeSuccess?.response;
    if (oauthTokenExchangeResponse == null) {
      // Device code has been expired or the timer is cancelled.
      return (null, closeReason);
    }

    final result = await _commonLoginWithMicrosoft(
      oauthTokenResponse: oauthTokenExchangeResponse,
      onProgressUpdate: (newProgress) => onProgressUpdate(newProgress),
    );

    return (result, closeReason);
  });

  // END: Device code

  // Common steps for logging with Microsoft either via device code or auth code.
  // Both will run differently but have [MicrosoftOauthTokenExchangeResponse]
  Future<AccountResult> _commonLoginWithMicrosoft({
    required MicrosoftOauthTokenExchangeResponse oauthTokenResponse,
    required void Function(MicrosoftAuthProgress newProgress) onProgressUpdate,
  }) async {
    onProgressUpdate(MicrosoftAuthProgress.requestingXboxToken);
    final xboxLiveTokenResponse = await microsoftAuthApi.requestXboxLiveToken(
      oauthTokenResponse,
    );

    onProgressUpdate(MicrosoftAuthProgress.requestingXstsToken);
    final xstsToken = await microsoftAuthApi.requestXSTSToken(
      xboxLiveTokenResponse,
    );
    onProgressUpdate(MicrosoftAuthProgress.loggingIntoMinecraft);
    final minecraftLoginResponse = await minecraftApi.loginToMinecraftWithXbox(
      xstsToken,
    );

    onProgressUpdate(MicrosoftAuthProgress.fetchingProfile);
    final minecraftProfileResponse = await minecraftApi.fetchMinecraftProfile(
      minecraftLoginResponse.accessToken,
    );

    onProgressUpdate(MicrosoftAuthProgress.checkingMinecraftJavaOwnership);
    final ownsMinecraftJava = await minecraftApi.checkMinecraftJavaOwnership(
      minecraftLoginResponse.accessToken,
    );

    final newAccount = MinecraftAccount.fromMinecraftProfileResponse(
      profileResponse: minecraftProfileResponse,
      oauthTokenResponse: oauthTokenResponse,
      loginResponse: minecraftLoginResponse,
      ownsMinecraftJava: ownsMinecraftJava,
    );

    final currentAccounts = loadAccounts();

    final existingAccountIndex = currentAccounts.all.indexWhere(
      (account) => account.id == newAccount.id,
    );
    final isAccountAlreadyAdded = existingAccountIndex != -1;

    final updatedAccounts =
        isAccountAlreadyAdded
            ? currentAccounts.copyWith(
              all: [
                ...currentAccounts.all..[existingAccountIndex] = newAccount,
              ],
              defaultAccountIndex: Wrapped.value(
                currentAccounts.defaultAccountIndex ?? 0,
              ),
            )
            : _getUpdatedAccountsOnCreate(
              defaultAccount: currentAccounts.defaultAccount,
              newAccount: newAccount,
              currentAccounts: currentAccounts,
            );
    accountStorage.saveAccounts(updatedAccounts);
    return AccountResult(
      newAccount: newAccount,
      updatedAccounts: updatedAccounts,
      hasUpdatedExistingAccount: isAccountAlreadyAdded,
    );
  }

  Future<AccountResult> refreshMicrosoftAccount(
    MinecraftAccount account, {
    required void Function(MicrosoftAuthProgress newProgress) onProgressUpdate,
  }) => _transformExceptions(() async {
    assert(
      account.accountType == AccountType.microsoft,
      'Expected the account type to be Microsoft, but received: ${account.accountType.name}',
    );

    // TODO: Do we need to check whether the refresh token was expired? Or handle it if access has been revoked.
    final microsoftRefreshToken = requireNotNull(
      account.microsoftAccountInfo?.microsoftOAuthRefreshToken,
      name: 'microsoftRefreshToken',
    );
    onProgressUpdate(MicrosoftAuthProgress.refreshingMicrosoftTokens);
    final oauthTokenResponse = await microsoftAuthApi
        .getNewTokensFromRefreshToken(microsoftRefreshToken);

    // Delete current cached skin images.
    await CachedNetworkImage.evictFromCache(account.headSkinImageUrl);
    await CachedNetworkImage.evictFromCache(account.fullSkinImageUrl);

    return _commonLoginWithMicrosoft(
      oauthTokenResponse: oauthTokenResponse,
      onProgressUpdate: onProgressUpdate,
    );
  });

  AccountResult createOfflineAccount({required String username}) {
    final newAccount = MinecraftAccount(
      accountType: AccountType.offline,
      id: const Uuid().v4(),
      username: username,
      microsoftAccountInfo: null,
      skins: List.unmodifiable([]),
      ownsMinecraftJava: null,
    );

    final currentAccounts = loadAccounts();

    final updatedAccounts = _getUpdatedAccountsOnCreate(
      newAccount: newAccount,
      defaultAccount: currentAccounts.defaultAccount,
      currentAccounts: currentAccounts,
    );
    accountStorage.saveAccounts(updatedAccounts);
    return AccountResult(
      newAccount: newAccount,
      updatedAccounts: updatedAccounts,
      hasUpdatedExistingAccount: false,
    );
  }

  MinecraftAccounts _getUpdatedAccountsOnCreate({
    required MinecraftAccount? defaultAccount,
    required MinecraftAccount newAccount,
    required MinecraftAccounts currentAccounts,
  }) {
    final updatedAccountsList = [newAccount, ...currentAccounts.all];
    return currentAccounts.copyWith(
      all: updatedAccountsList,
      defaultAccountIndex: Wrapped.value(
        defaultAccount != null
            ? updatedAccountsList.indexWhere(
              (account) => defaultAccount.id == account.id,
            )
            : 0,
      ),
    );
  }

  AccountResult updateOfflineAccount({
    required int index,
    required String username,
  }) {
    final currentMinecraftAccounts = loadAccounts();
    final updatedAccount = currentMinecraftAccounts.all[index].copyWith(
      username: username,
    );
    final updatedAccounts = currentMinecraftAccounts.copyWith(
      all: [...currentMinecraftAccounts.all..[index] = updatedAccount],
    );

    accountStorage.saveAccounts(updatedAccounts);
    return AccountResult(
      newAccount: updatedAccount,
      updatedAccounts: updatedAccounts,
      hasUpdatedExistingAccount: true,
    );
  }

  MinecraftAccounts removeAccount({
    required int index,
    required MinecraftAccounts currentMinecraftAccounts,
  }) {
    final updatedAccountsList = [...currentMinecraftAccounts.all]
      ..removeAt(index);
    final updatedAccounts = currentMinecraftAccounts.copyWith(
      all: updatedAccountsList,
      defaultAccountIndex: Wrapped.value(
        updatedAccountsList.getNewIndexAfterRemoval(index),
      ),
    );
    accountStorage.saveAccounts(updatedAccounts);
    return updatedAccounts;
  }

  MinecraftAccounts loadAccounts() {
    try {
      return accountStorage.loadAccounts();
    } on Exception catch (e, stackTrace) {
      throw AccountManagerException.unknown(e.toString(), stackTrace);
    }
  }

  MinecraftAccounts updateDefaultAccount({
    required int newDefaultAccountIndex,
    required MinecraftAccounts currentAccounts,
  }) {
    final updatedAccounts = currentAccounts.copyWith(
      defaultAccountIndex: Wrapped.value(newDefaultAccountIndex),
    );
    accountStorage.saveAccounts(updatedAccounts);
    return updatedAccounts;
  }
}

@immutable
class AuthCodeSuccessLoginPageContent {
  const AuthCodeSuccessLoginPageContent({
    required this.pageTitle,
    required this.title,
    required this.subtitle,
    required this.pageLangCode,
    required this.pageDir,
  });
  final String pageTitle;
  final String title;
  final String subtitle;
  final String pageLangCode;
  final String pageDir;
}

// Since the authorization code flow requires a redirect URI,
// the app temporarily starts a local server to handle the redirect request,
// which contains the authorization code needed to complete login.
@visibleForTesting
String buildAuthCodeSuccessPageHtml(AuthCodeSuccessLoginPageContent content) =>
    '''
<!DOCTYPE html>
<html lang="${content.pageLangCode}" dir="${content.pageDir}">
<head>
  <meta charset="UTF-8" />
  <title>${content.pageTitle}</title>
  <style>
    html, body {
      margin: 0;
      padding: 0;
      height: 100%;
      background: #f3f4f6;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .box {
      text-align: center;
      background: white;
      padding: 2rem 3rem;
      border-radius: 1rem;
      box-shadow: 0 10px 30px rgba(0,0,0,0.1);
    }
    .box h1 {
      margin: 0;
      font-size: 1.5rem;
      color: #2563eb;
    }
    .box p {
      margin-top: 0.5rem;
      color: #4b5563;
    }
  </style>
</head>
<body>
  <div class="box">
    <h1>✅ ${content.title}</h1>
    <p>${content.subtitle}</p>
  </div>
</body>
</html>
''';

// Result when login with an existing Microsoft account, or creating/updating
// an offline account.
@immutable
class AccountResult {
  const AccountResult({
    required this.newAccount,
    required this.updatedAccounts,
    required this.hasUpdatedExistingAccount,
  });

  final MinecraftAccount newAccount;
  final MinecraftAccounts updatedAccounts;
  final bool hasUpdatedExistingAccount;
}

enum MicrosoftAuthProgress {
  waitingForUserLogin,
  refreshingMicrosoftTokens,
  exchangingAuthCode,
  exchangingDeviceCode,
  requestingXboxToken,
  requestingXstsToken,
  loggingIntoMinecraft,
  fetchingProfile,
  checkingMinecraftJavaOwnership,
}

enum DeviceCodeTimerCloseReason {
  codeExpired,
  normal, // Either the user requested to cancel the timer or the user logged in
}
