import 'dart:async';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../common/constants/constants.dart';
import '../../../common/constants/project_info_constants.dart';
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
import '../account_utils.dart';
import '../minecraft_skin_ext.dart';
import 'async_timer.dart';
import 'http_server_ext.dart';
import 'image_cache_service/image_cache_service.dart';
import 'minecraft_account_manager_exceptions.dart';

class MinecraftAccountManager {
  MinecraftAccountManager({
    required this.microsoftAuthApi,
    required this.minecraftApi,
    required this.accountStorage,
    required this.imageCacheService,
  });

  @visibleForTesting
  final MicrosoftAuthApi microsoftAuthApi;
  @visibleForTesting
  final MinecraftApi minecraftApi;

  // TODO: Avoid loading the accounts everytime when removing, updating or adding an account? Track: accountStorage.loadAccounts() and see https://bloclibrary.dev/architecture/#connecting-blocs-through-domain
  @visibleForTesting
  final AccountStorage accountStorage;

  @visibleForTesting
  final ImageCacheService imageCacheService;

  Future<T> _transformExceptions<T>(
    Future<T> Function() run, {
    void Function(MicrosoftAuthException e)? onMicrosoftAuthException,
  }) async {
    try {
      return await run();
    } on MicrosoftAuthException catch (e) {
      onMicrosoftAuthException?.call(e);
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
      ProjectInfoConstants.microsoftLoginRedirectPort,
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
    required OnAuthProgressUpdateAuthCodeCallback onProgressUpdate,
    // The page content is not hardcoded for localization.
    required MicrosoftAuthCodeResponsePageVariants authCodeResponsePageVariants,
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

    Future<void> respondAndStopServer(String html) async {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..write(html);
      await request.response.close();
      await stopServer();
    }

    final code =
        request.uri.queryParameters[MicrosoftConstants
            .loginRedirectAuthCodeQueryParamName];

    final error =
        request.uri.queryParameters[MicrosoftConstants
            .loginRedirectErrorQueryParamName];
    final errorDescription =
        request.uri.queryParameters[MicrosoftConstants
            .loginRedirectErrorDescriptionQueryParamName];

    if (error != null) {
      if (error == MicrosoftConstants.loginRedirectAccessDeniedErrorCode) {
        await respondAndStopServer(
          buildAuthCodeResultHtmlPage(
            authCodeResponsePageVariants.accessDenied,
            isSuccess: false,
          ),
        );
        throw AccountManagerException.microsoftAuthCodeDenied();
      }

      await respondAndStopServer(
        buildAuthCodeResultHtmlPage(
          authCodeResponsePageVariants.unknownError(
            error,
            errorDescription.toString(),
          ),
          isSuccess: false,
        ),
      );
      throw AccountManagerException.microsoftAuthCodeRedirect(
        error: error,
        errorDescription: errorDescription.toString(),
      );
    }
    if (code == null) {
      await respondAndStopServer(
        buildAuthCodeResultHtmlPage(
          authCodeResponsePageVariants.missingAuthCode,
          isSuccess: false,
        ),
      );
      throw AccountManagerException.microsoftMissingAuthCode();
    }
    await respondAndStopServer(
      buildAuthCodeResultHtmlPage(
        authCodeResponsePageVariants.approved,
        isSuccess: true,
      ),
    );

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
  AsyncTimer<MicrosoftDeviceCodeApproved?>? deviceCodePollingTimer;

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
  bool cancelDeviceCodePollingTimer([MicrosoftDeviceCodeApproved? result]) {
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
    required OnAuthProgressUpdateCallback onProgressUpdate,
    required OnDeviceCodeAvailableCallback onDeviceCodeAvailable,
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

    var closeReason = DeviceCodeTimerCloseReason.cancelledByUser;

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
        // Check if the device code has expired before making the API call.
        // NOTE: When using DateTime.now() instead of clock.now(), the related test
        // will still succeed, but due to the Future.delayed() callback, commenting it out
        // will cause the test to fail and require clock.now().
        final hasDeviceCodeExpired = clock.now().isAfter(deviceCodeExpiresAt);
        if (hasDeviceCodeExpired) {
          cancelTimerOnExpiration();
          return;
        }
        final checkDeviceCodeResult = await microsoftAuthApi
            .checkDeviceCodeStatus(deviceCodeResponse);
        switch (checkDeviceCodeResult) {
          case MicrosoftDeviceCodeApproved():
            closeReason = DeviceCodeTimerCloseReason.approved;
            cancelDeviceCodePollingTimer(checkDeviceCodeResult);
          case MicrosoftDeviceCodeDeclined():
            closeReason = DeviceCodeTimerCloseReason.declined;
            cancelDeviceCodePollingTimer();
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
        'This is likely a bug, the timer should be cancelled at this point',
      );
      cancelDeviceCodePollingTimer();
    }

    // Response of exchanging the device code.
    final oauthTokenExchangeResponse = deviceCodeSuccess?.response;
    if (oauthTokenExchangeResponse == null) {
      // Device code has been expired or the timer is cancelled.
      return (null, closeReason);
    }

    onProgressUpdate(MicrosoftAuthProgress.exchangingDeviceCode);
    final result = await _commonLoginWithMicrosoft(
      oauthTokenResponse: oauthTokenExchangeResponse,
      onProgressUpdate: (newProgress) => onProgressUpdate(newProgress),
    );

    return (result, closeReason);
  });

  // END: Device code

  // Common steps for logging in to Minecraft with Microsoft either via device code,
  // auth code or when refreshing the account.
  // All run differently but have [MicrosoftOauthTokenExchangeResponse] in common.
  Future<AccountResult> _commonLoginWithMicrosoft({
    required MicrosoftOauthTokenExchangeResponse oauthTokenResponse,
    required OnAuthProgressUpdateCallback onProgressUpdate,
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

    onProgressUpdate(MicrosoftAuthProgress.checkingMinecraftJavaOwnership);
    final ownsMinecraftJava = await minecraftApi.checkMinecraftJavaOwnership(
      minecraftLoginResponse.accessToken,
    );

    if (!ownsMinecraftJava) {
      throw AccountManagerException.minecraftEntitlementAbsent();
    }

    onProgressUpdate(MicrosoftAuthProgress.fetchingProfile);
    final minecraftProfileResponse = await minecraftApi.fetchMinecraftProfile(
      minecraftLoginResponse.accessToken,
    );

    final newAccount = accountFromResponses(
      profileResponse: minecraftProfileResponse,
      oauthTokenResponse: oauthTokenResponse,
      loginResponse: minecraftLoginResponse,
      ownsMinecraftJava: ownsMinecraftJava,
    );

    final existingAccounts = accountStorage.loadAccounts();

    final existingAccountIndex = existingAccounts.list.indexWhere(
      (account) => account.id == newAccount.id,
    );
    final isAccountAlreadyAdded = existingAccountIndex != -1;

    final updatedAccounts =
        isAccountAlreadyAdded
            ? _getUpdatedAccountsOnUpdate(
              updatedAccount: newAccount,
              existingAccounts: existingAccounts,
              existingAccountIndex: existingAccountIndex,
            )
            : _getUpdatedAccountsOnCreate(
              newAccount: newAccount,
              existingAccounts: existingAccounts,
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
    required OnAuthProgressUpdateCallback onProgressUpdate,
  }) => _transformExceptions(
    () async {
      assert(
        account.accountType == AccountType.microsoft,
        'Expected the account type to be Microsoft, but received: ${account.accountType.name}',
      );

      final microsoftAccountInfo = account.microsoftAccountInfo;
      if (microsoftAccountInfo == null) {
        throw ArgumentError.value(
          account,
          'account',
          'The $MicrosoftAccountInfo must not be null when refreshing'
              ' the Microsoft account. Account Type: ${account.accountType.name}',
        );
      }
      final microsoftRefreshToken =
          microsoftAccountInfo.microsoftOAuthRefreshToken;

      _requireUnexpiredMicrosoftRefreshToken(account);

      onProgressUpdate(MicrosoftAuthProgress.refreshingMicrosoftTokens);
      final oauthTokenResponse = await microsoftAuthApi
          .getNewTokensFromRefreshToken(microsoftRefreshToken.value);

      // Delete current cached skin images.
      await imageCacheService.evictFromCache(account.headSkinImageUrl);
      await imageCacheService.evictFromCache(account.fullSkinImageUrl);

      return _commonLoginWithMicrosoft(
        oauthTokenResponse: oauthTokenResponse,
        onProgressUpdate: onProgressUpdate,
      );
    },
    onMicrosoftAuthException: (e) {
      if (e is ExpiredOrUnauthorizedRefreshTokenMicrosoftAuthException) {
        final existingAccounts = accountStorage.loadAccounts();
        final updatedAccount = _markNeedsReAuthentication(account);
        final accountsReAuthUpdated = existingAccounts.updateById(
          account.id,
          (_) => updatedAccount,
        );
        accountStorage.saveAccounts(accountsReAuthUpdated);
        throw AccountManagerException.microsoftExpiredOrUnauthorizedRefreshToken(
          updatedAccount,
        );
      }
    },
  );

  MinecraftAccounts _getUpdatedAccountsOnUpdate({
    required MinecraftAccount updatedAccount,
    required MinecraftAccounts existingAccounts,
    required int existingAccountIndex,
  }) => existingAccounts.copyWith(
    all: List<MinecraftAccount>.from(existingAccounts.list)
      ..[existingAccountIndex] = updatedAccount,
    defaultAccountId: Wrapped.value(
      existingAccounts.defaultAccountId ?? updatedAccount.id,
    ),
  );

  MinecraftAccounts _getUpdatedAccountsOnCreate({
    required MinecraftAccount newAccount,
    required MinecraftAccounts existingAccounts,
  }) {
    final updatedAccountsList = [newAccount, ...existingAccounts.list];
    final currentDefaultAccount = existingAccounts.defaultAccount;
    return existingAccounts.copyWith(
      all: updatedAccountsList,
      defaultAccountId: Wrapped.value(
        currentDefaultAccount != null
            ? updatedAccountsList
                .firstWhere((account) => currentDefaultAccount.id == account.id)
                .id
            : newAccount.id,
      ),
    );
  }

  AccountResult createOfflineAccount({required String username}) {
    final newAccount = MinecraftAccount(
      accountType: AccountType.offline,
      id: const Uuid().v4(),
      username: username,
      microsoftAccountInfo: null,
      skins: List.unmodifiable([]),
      capes: List.unmodifiable([]),
      ownsMinecraftJava: null,
    );

    final existingAccounts = accountStorage.loadAccounts();

    final updatedAccounts = _getUpdatedAccountsOnCreate(
      newAccount: newAccount,
      existingAccounts: existingAccounts,
    );
    accountStorage.saveAccounts(updatedAccounts);
    return AccountResult(
      newAccount: newAccount,
      updatedAccounts: updatedAccounts,
      hasUpdatedExistingAccount: false,
    );
  }

  AccountResult updateOfflineAccount({
    required String accountId,
    required String username,
  }) {
    final existingAccounts = accountStorage.loadAccounts();
    final index = existingAccounts.list.indexWhere(
      (account) => account.id == accountId,
    );

    final updatedAccount = existingAccounts.list[index].copyWith(
      username: username,
    );

    final updatedAccounts = existingAccounts.copyWith(
      all: List<MinecraftAccount>.from(existingAccounts.list)
        ..[index] = updatedAccount,
    );

    accountStorage.saveAccounts(updatedAccounts);
    return AccountResult(
      newAccount: updatedAccount,
      updatedAccounts: updatedAccounts,
      hasUpdatedExistingAccount: true,
    );
  }

  MinecraftAccounts removeAccount(String accountId) {
    final existingAccounts = accountStorage.loadAccounts();
    final removedAccountIndex = existingAccounts.list.indexWhere(
      (account) => account.id == accountId,
    );

    final updatedAccountsList = List<MinecraftAccount>.from(
      existingAccounts.list,
    )..removeWhere((account) => account.id == accountId);

    final updatedAccounts = existingAccounts.copyWith(
      all: updatedAccountsList,
      defaultAccountId: Wrapped.value(
        updatedAccountsList
            .getReplacementElementAfterRemoval(removedAccountIndex)
            ?.id,
      ),
    );
    accountStorage.saveAccounts(updatedAccounts);
    return updatedAccounts;
  }

  void _requireUnexpiredMicrosoftRefreshToken(MinecraftAccount account) {
    if (account.microsoftAccountInfo?.needsReAuthentication ?? false) {
      throw AccountManagerException.microsoftRefreshTokenExpired();
    }
    // TODO: Do we also need to check the expiresAt? The expiresAt will be updated
    //  when loading the accounts but it might expire after loading them while using the launcher (rare case since it expires in 90 days). Also handle update from UI if done, review this fully and update tests
  }

  MinecraftAccount _markNeedsReAuthentication(
    MinecraftAccount existingAccount,
  ) {
    final updatedAccount = existingAccount.copyWith(
      microsoftAccountInfo: existingAccount.microsoftAccountInfo?.copyWith(
        needsReAuthentication: true,
      ),
    );
    return updatedAccount;
  }

  MinecraftAccounts loadAccounts() {
    try {
      final loadedAccounts = accountStorage.loadAccounts();

      bool hasUpdates = false;
      final accountsReauthUpdated = loadedAccounts.copyWith(
        all:
            loadedAccounts.list.map((account) {
              final microsoftAccountInfo = account.microsoftAccountInfo;

              if (microsoftAccountInfo != null &&
                  microsoftAccountInfo.microsoftOAuthRefreshToken.hasExpired) {
                final newAccount = _markNeedsReAuthentication(account);
                hasUpdates = true;

                return newAccount;
              }
              return account;
            }).toList(),
      );
      if (hasUpdates) {
        accountStorage.saveAccounts(accountsReauthUpdated);
        return accountsReauthUpdated;
      }

      return loadedAccounts;
    } on Exception catch (e, stackTrace) {
      throw AccountManagerException.unknown(e.toString(), stackTrace);
    }
  }

  MinecraftAccounts updateDefaultAccount({
    required String newDefaultAccountId,
  }) {
    final existingAccounts = accountStorage.loadAccounts();
    final updatedAccounts = existingAccounts.copyWith(
      defaultAccountId: Wrapped.value(newDefaultAccountId),
    );
    accountStorage.saveAccounts(updatedAccounts);
    return updatedAccounts;
  }

  // Refreshes a Microsoft account if the Minecraft access token is expired.
  @visibleForTesting
  @experimental // TODO: More consideration is needed, test it with skin update feature first
  Future<MinecraftAccount> refreshMinecraftAccessTokenIfExpired(
    MinecraftAccount account, {
    required OnAuthProgressUpdateCallback onRefreshProgressUpdate,
  }) async {
    final microsoftAccountInfo = account.microsoftAccountInfo;
    if (microsoftAccountInfo == null) {
      throw ArgumentError.value(
        account,
        'account',
        'The $MicrosoftAccountInfo must not be null when validating the '
            'Minecraft access token. Account Type: ${account.accountType.name}',
      );
    }
    final hasExpired = microsoftAccountInfo.minecraftAccessToken.hasExpired;
    if (hasExpired) {
      // TODO: Test the handling of Microsoft refresh token expiration?

      _requireUnexpiredMicrosoftRefreshToken(account);

      onRefreshProgressUpdate(MicrosoftAuthProgress.refreshingMicrosoftTokens);
      final response = await microsoftAuthApi.getNewTokensFromRefreshToken(
        microsoftAccountInfo.microsoftOAuthRefreshToken.value,
      );

      onRefreshProgressUpdate(MicrosoftAuthProgress.requestingXboxToken);
      final xboxResponse = await microsoftAuthApi.requestXboxLiveToken(
        response,
      );

      onRefreshProgressUpdate(MicrosoftAuthProgress.requestingXstsToken);
      final xstsResponse = await microsoftAuthApi.requestXSTSToken(
        xboxResponse,
      );

      onRefreshProgressUpdate(MicrosoftAuthProgress.loggingIntoMinecraft);
      final loginResponse = await minecraftApi.loginToMinecraftWithXbox(
        xstsResponse,
      );
      final refreshedAccount = account.copyWith(
        microsoftAccountInfo: microsoftAccountInfo.copyWith(
          minecraftAccessToken: ExpirableToken(
            value: loginResponse.accessToken,
            expiresAt: expiresInToExpiresAt(loginResponse.expiresIn),
          ),
          microsoftOAuthAccessToken: ExpirableToken(
            value: response.accessToken,
            expiresAt: expiresInToExpiresAt(loginResponse.expiresIn),
          ),
          microsoftOAuthRefreshToken: ExpirableToken(
            value: response.refreshToken,
            expiresAt: _microsoftRefreshTokenExpiresAt(),
          ),
        ),
      );

      return refreshedAccount;
    }
    return account;
  }

  // NOTE: The Microsoft API doesn't provide the expiration date for the refresh token,
  // it's 90 days according to https://learn.microsoft.com/en-us/entra/identity-platform/refresh-tokens#token-lifetime.
  // The app will always need to handle the case where it's expired or access is revoked when sending the request.
  DateTime _microsoftRefreshTokenExpiresAt() => clock.now().add(
    const Duration(days: MicrosoftConstants.refreshTokenExpiresInDays),
  );

  @visibleForTesting
  MinecraftAccount accountFromResponses({
    required MinecraftProfileResponse profileResponse,
    required MicrosoftOauthTokenExchangeResponse oauthTokenResponse,
    required MinecraftLoginResponse loginResponse,
    required bool ownsMinecraftJava,
  }) => MinecraftAccount(
    id: profileResponse.id,
    username: profileResponse.name,
    accountType: AccountType.microsoft,
    microsoftAccountInfo: MicrosoftAccountInfo(
      microsoftOAuthAccessToken: ExpirableToken(
        value: oauthTokenResponse.accessToken,
        expiresAt: expiresInToExpiresAt(oauthTokenResponse.expiresIn),
      ),
      microsoftOAuthRefreshToken: ExpirableToken(
        value: oauthTokenResponse.refreshToken,
        expiresAt: _microsoftRefreshTokenExpiresAt(),
      ),
      minecraftAccessToken: ExpirableToken(
        value: loginResponse.accessToken,
        expiresAt: expiresInToExpiresAt(loginResponse.expiresIn),
      ),
      needsReAuthentication: false,
    ),
    skins:
        profileResponse.skins
            .map(
              (skin) => MinecraftSkin(
                id: skin.id,
                state: skin.state,
                url: skin.url,
                textureKey: skin.textureKey,
                variant: skin.variant,
              ),
            )
            .toList(),
    capes:
        profileResponse.capes
            .map(
              (cape) => MinecraftCape(
                id: cape.id,
                state: cape.state,
                url: cape.url,
                alias: cape.alias,
              ),
            )
            .toList(),
    ownsMinecraftJava: ownsMinecraftJava,
  );
}

@immutable
class MicrosoftAuthCodeResponsePageContent {
  const MicrosoftAuthCodeResponsePageContent({
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

@immutable
class MicrosoftAuthCodeResponsePageVariants {
  const MicrosoftAuthCodeResponsePageVariants({
    required this.approved,
    required this.accessDenied,
    required this.missingAuthCode,
    required this.unknownError,
  });

  final MicrosoftAuthCodeResponsePageContent approved;
  final MicrosoftAuthCodeResponsePageContent accessDenied;
  final MicrosoftAuthCodeResponsePageContent missingAuthCode;
  final MicrosoftAuthCodeResponsePageContent Function(
    String errorCode,
    String errorDescription,
  )
  unknownError;
}

// Since the authorization code flow requires a redirect URI,
// the app temporarily starts a local server to handle the redirect request,
// which contains the authorization code needed to complete login.
@visibleForTesting
String buildAuthCodeResultHtmlPage(
  MicrosoftAuthCodeResponsePageContent content, {
  required bool isSuccess,
}) => '''
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
    <h1>${isSuccess ? '✅' : '❌'} ${content.title}</h1>
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
  approved,
  declined,
  cancelledByUser,
}

@visibleForTesting
typedef OnAuthProgressUpdateAuthCodeCallback =
    void Function(
      MicrosoftAuthProgress newProgress, {

      // TODO: Maybe move authCodeLoginUrl in a separate callback (like OnDeviceCodeAvailableCallback) and use OnAuthProgressUpdateCallback instead? Also update tests
      /// Not null if [newProgress] is [MicrosoftAuthProgress.waitingForUserLogin]
      String? authCodeLoginUrl,
    });

@visibleForTesting
typedef OnAuthProgressUpdateCallback =
    void Function(MicrosoftAuthProgress newProgress);

@visibleForTesting
typedef OnDeviceCodeAvailableCallback = void Function(String deviceCode);
