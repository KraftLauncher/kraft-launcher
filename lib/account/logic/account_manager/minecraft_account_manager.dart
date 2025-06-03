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
import '../../data/microsoft_auth_api/auth_methods/microsoft_device_code_flow.dart';
import '../../data/microsoft_auth_api/microsoft_auth_api.dart';
import '../../data/microsoft_auth_api/microsoft_auth_exceptions.dart';
import '../../data/minecraft_account/minecraft_account.dart';
import '../../data/minecraft_account/minecraft_accounts.dart';
import '../../data/minecraft_api/minecraft_api.dart';
import '../../data/minecraft_api/minecraft_api_exceptions.dart';
import '../account_repository.dart';
import '../account_utils.dart';
import '../minecraft_skin_ext.dart';
import 'async_timer.dart';
import 'http_server_ext.dart';
import 'image_cache_service/image_cache_service.dart';
import 'minecraft_account_manager_exceptions.dart';

// TODO: Refactor this class for clear separation of concerns and easier testing, maintainability and readability, fix everything in https://github.com/KraftLauncher/kraft-launcher/commit/08faf5b9075a95606d27fbcfaf5dce56beed1ac0
//  What also needs refactoring: AccountCubit, MicrosoftAccountHandlerCubit

class MinecraftAccountManager {
  MinecraftAccountManager({
    required this.microsoftAuthApi,
    required this.minecraftApi,
    required this.accountRepository,
    required this.imageCacheService,
  });

  @visibleForTesting
  final MicrosoftAuthApi microsoftAuthApi;
  @visibleForTesting
  final MinecraftApi minecraftApi;

  @visibleForTesting
  final AccountRepository accountRepository;

  @visibleForTesting
  final ImageCacheService imageCacheService;

  Future<T> _transformExceptions<T>(
    Future<T> Function() run, {
    Future<void> Function(MicrosoftAuthException e)? onMicrosoftAuthException,
  }) async {
    try {
      return await run();
    } on MicrosoftAuthException catch (e) {
      await onMicrosoftAuthException?.call(e);
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
      oauthTokenResponse.accessToken,
    );

    onProgressUpdate(MicrosoftAuthProgress.requestingXstsToken);
    final xstsTokenResponse = await microsoftAuthApi.requestXSTSToken(
      xboxLiveTokenResponse.xboxToken,
    );
    onProgressUpdate(MicrosoftAuthProgress.loggingIntoMinecraft);
    final minecraftLoginResponse = await minecraftApi.loginToMinecraftWithXbox(
      xstsToken: xstsTokenResponse.xboxToken,
      xstsUserHash: xstsTokenResponse.userHash,
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

    final isAccountAlreadyAdded = accountRepository.accountExists(
      newAccount.id,
    );

    if (isAccountAlreadyAdded) {
      await accountRepository.updateAccount(newAccount);
    } else {
      await accountRepository.addAccount(newAccount);
    }
    return AccountResult(
      newAccount: newAccount,
      updatedAccounts:
          accountRepository
              .accounts, // TODO: WE MAY NEED BETTER SOLUTION, maybe make the cubit depends AccountRepository?
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
      final microsoftRefreshToken = microsoftAccountInfo.microsoftRefreshToken;

      _throwsIfNeedsMicrosoftReAuth(account);

      onProgressUpdate(MicrosoftAuthProgress.refreshingMicrosoftTokens);
      final oauthTokenResponse = await microsoftAuthApi
      // TODO: Unit tests should expect the code to throws StateError for this point
      .getNewTokensFromRefreshToken(
        microsoftRefreshToken.value ??
            (throw StateError(
              'Microsoft refresh token should not be null to refresh the account',
            )),
      );

      // Delete current cached skin images.
      await imageCacheService.evictFromCache(account.headSkinImageUrl);
      await imageCacheService.evictFromCache(account.fullSkinImageUrl);

      return _commonLoginWithMicrosoft(
        oauthTokenResponse: oauthTokenResponse,
        onProgressUpdate: onProgressUpdate,
      );
    },
    onMicrosoftAuthException: (e) async {
      if (e is ExpiredOrUnauthorizedRefreshTokenMicrosoftAuthException) {
        final updatedAccount = account.copyWith(
          microsoftAccountInfo: account.microsoftAccountInfo!.copyWith(
            reauthRequiredReason: MicrosoftReauthRequiredReason.accessRevoked,
          ),
        );
        await accountRepository.updateAccount(updatedAccount);
        throw AccountManagerException.microsoftExpiredOrUnauthorizedRefreshToken(
          updatedAccount,
        );
      }
    },
  );

  Future<AccountResult> createOfflineAccount({required String username}) async {
    final newAccount = MinecraftAccount(
      accountType: AccountType.offline,
      id: const Uuid().v4(),
      username: username,
      microsoftAccountInfo: null,
      skins: List.unmodifiable([]),
      capes: List.unmodifiable([]),
      ownsMinecraftJava: null,
    );

    await accountRepository.addAccount(newAccount);

    return AccountResult(
      newAccount: newAccount,
      updatedAccounts:
          accountRepository
              .accounts, // TODO: WE MAY NEED BETTER SOLUTION, maybe make the cubit depends AccountRepository?
      hasUpdatedExistingAccount: false,
    );
  }

  Future<AccountResult> updateOfflineAccount({
    required String accountId,
    required String username,
  }) async {
    final updatedAccount = accountRepository.accounts.list
        .findById(accountId)
        .copyWith(username: username);

    await accountRepository.updateAccount(updatedAccount);

    return AccountResult(
      newAccount: updatedAccount,
      updatedAccounts:
          accountRepository
              .accounts, // TODO: WE MAY NEED BETTER SOLUTION, maybe make the cubit depends AccountRepository?
      hasUpdatedExistingAccount: true,
    );
  }

  Future<MinecraftAccounts> removeAccount(String accountId) async {
    await accountRepository.removeAccount(accountId);

    return accountRepository
        .accounts; // TODO: WE MAY NEED BETTER SOLUTION, maybe make the cubit depends AccountRepository?
  }

  void _throwsIfNeedsMicrosoftReAuth(MinecraftAccount account) {
    final reAuthRequiredReason =
        account.microsoftAccountInfo?.reauthRequiredReason;
    if (reAuthRequiredReason != null) {
      throw AccountManagerException.microsoftReAuthRequired(
        reAuthRequiredReason,
      );
    }
    // TODO: Do we also need to check the expiresAt? The expiresAt will be updated
    //  when loading the accounts but it might expire after loading them while using the launcher (rare case since it expires in 90 days). Also handle update from UI if done, review this fully and update tests
  }

  Future<MinecraftAccounts> loadAccounts() async {
    try {
      // TODO: Should we use such functions directly in the cubit?

      final loadedAccounts = await accountRepository.loadAccounts();

      return loadedAccounts;
    } on Exception catch (e, stackTrace) {
      throw AccountManagerException.unknown(e.toString(), stackTrace);
    }
  }

  Future<MinecraftAccounts> updateDefaultAccount({
    required String newDefaultAccountId,
  }) async {
    await accountRepository.updateDefaultAccount(newDefaultAccountId);
    return accountRepository
        .accounts; // TODO: WE MAY NEED BETTER SOLUTION, maybe make the cubit depends AccountRepository?
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
    final hasExpired =
        microsoftAccountInfo.minecraftAccessToken.expiresAt.hasExpired;
    if (hasExpired) {
      // TODO: Test the handling of Microsoft refresh token expiration? (Manually)

      _throwsIfNeedsMicrosoftReAuth(account);

      onRefreshProgressUpdate(MicrosoftAuthProgress.refreshingMicrosoftTokens);
      final response = await microsoftAuthApi.getNewTokensFromRefreshToken(
        // TODO: Unit tests should expect the code to throws StateError for this point
        microsoftAccountInfo.microsoftRefreshToken.value ??
            (throw StateError(
              'Microsoft refresh token should not be null to refresh the Minecraft access token',
            )),
      );

      onRefreshProgressUpdate(MicrosoftAuthProgress.requestingXboxToken);
      final xboxResponse = await microsoftAuthApi.requestXboxLiveToken(
        response.accessToken,
      );

      onRefreshProgressUpdate(MicrosoftAuthProgress.requestingXstsToken);
      final xstsTokenResponse = await microsoftAuthApi.requestXSTSToken(
        xboxResponse.xboxToken,
      );

      onRefreshProgressUpdate(MicrosoftAuthProgress.loggingIntoMinecraft);
      final loginResponse = await minecraftApi.loginToMinecraftWithXbox(
        xstsToken: xstsTokenResponse.xboxToken,
        xstsUserHash: xstsTokenResponse.userHash,
      );
      final refreshedAccount = account.copyWith(
        microsoftAccountInfo: microsoftAccountInfo.copyWith(
          minecraftAccessToken: ExpirableToken(
            value: loginResponse.accessToken,
            expiresAt: expiresInToExpiresAt(loginResponse.expiresIn),
          ),
          microsoftRefreshToken: ExpirableToken(
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
  }) {
    MinecraftCosmeticState toCosmeticState(MinecraftApiCosmeticState api) =>
        switch (api) {
          MinecraftApiCosmeticState.active => MinecraftCosmeticState.active,
          MinecraftApiCosmeticState.inactive => MinecraftCosmeticState.inactive,
        };
    return MinecraftAccount(
      id: profileResponse.id,
      username: profileResponse.name,
      accountType: AccountType.microsoft,
      microsoftAccountInfo: MicrosoftAccountInfo(
        microsoftRefreshToken: ExpirableToken(
          value: oauthTokenResponse.refreshToken,
          expiresAt: _microsoftRefreshTokenExpiresAt(),
        ),
        minecraftAccessToken: ExpirableToken(
          value: loginResponse.accessToken,
          expiresAt: expiresInToExpiresAt(loginResponse.expiresIn),
        ),
        // Account created and logged in; re-authentication is not required
        reauthRequiredReason: null,
      ),
      skins:
          profileResponse.skins
              .map(
                (skin) => MinecraftSkin(
                  id: skin.id,
                  state: toCosmeticState(skin.state),
                  url: skin.url,
                  textureKey: skin.textureKey,
                  variant: switch (skin.variant) {
                    MinecraftApiSkinVariant.classic =>
                      MinecraftSkinVariant.classic,
                    MinecraftApiSkinVariant.slim => MinecraftSkinVariant.slim,
                  },
                ),
              )
              .toList(),
      capes:
          profileResponse.capes
              .map(
                (cape) => MinecraftCape(
                  id: cape.id,
                  state: toCosmeticState(cape.state),
                  url: cape.url,
                  alias: cape.alias,
                ),
              )
              .toList(),
      ownsMinecraftJava: ownsMinecraftJava,
    );
  }
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

  // TODO: This could be either updatedAccount or newAccount, avoid this approach fully (after the next big refactor)
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
