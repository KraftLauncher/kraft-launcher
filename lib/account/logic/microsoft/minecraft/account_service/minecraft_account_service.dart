import 'package:meta/meta.dart';

import '../../../../data/microsoft_auth_api/microsoft_auth_api.dart';
import '../../../../data/microsoft_auth_api/microsoft_auth_api_exceptions.dart'
    as microsoft_auth_api_exceptions;
import '../../../../data/minecraft_account_api/minecraft_account_api_exceptions.dart'
    as minecraft_account_api_exceptions;
import '../../../account_repository.dart';
import '../../../launcher_minecraft_account/minecraft_account.dart';
import '../../auth_flows/auth_code/microsoft_auth_code_flow.dart';
import '../../auth_flows/auth_code/microsoft_auth_code_flow_exceptions.dart'
    as microsoft_auth_code_flow_exceptions;
import '../../auth_flows/device_code/microsoft_device_code_flow.dart';
import '../../microsoft_oauth_flow_controller.dart';
import '../account_refresher/minecraft_account_refresher.dart';
import '../account_refresher/minecraft_account_refresher_exceptions.dart'
    as minecraft_account_refresher_exceptions;
import '../account_resolver/minecraft_account_resolver.dart';
import '../account_resolver/minecraft_account_resolver_exceptions.dart'
    as minecraft_account_resolver_exceptions;
import 'minecraft_account_service_exceptions.dart'
    as minecraft_account_service_exceptions;
import 'minecraft_auth_progress.dart';

/// A service for logging into and managing Minecraft accounts via Microsoft.
///
/// Handles Microsoft OAuth login (auth code and device code), refreshes tokens,
/// resolves Minecraft accounts, and persists them via [AccountRepository].
///
/// All operations are specific to **Microsoft-backed Minecraft accounts**.
class MinecraftAccountService {
  MinecraftAccountService({
    required this.accountRepository,
    required this.microsoftOAuthFlowController,
    required this.minecraftAccountResolver,
    required this.minecraftAccountRefresher,
  });

  @visibleForTesting
  final AccountRepository accountRepository;
  @visibleForTesting
  final MicrosoftOAuthFlowController microsoftOAuthFlowController;
  @visibleForTesting
  final MinecraftAccountResolver minecraftAccountResolver;
  @visibleForTesting
  final MinecraftAccountRefresher minecraftAccountRefresher;

  Future<T> _transformExceptions<T>(
    Future<T> Function() run, {
    Future<void> Function(
      microsoft_auth_api_exceptions.MicrosoftAuthApiException e,
    )?
    onMicrosoftAuthApiException,
  }) async {
    // TODO: The current solution is not scalable enough. Avoid using exceptions for possible failures, and only throw Dart errors (major refactor). Consider using Result pattern again?
    try {
      return await run();
    } on microsoft_auth_api_exceptions.MicrosoftAuthApiException catch (e) {
      throw minecraft_account_service_exceptions.MicrosoftAuthApiException(e);
    } on minecraft_account_api_exceptions.MinecraftAccountApiException catch (
      e
    ) {
      throw minecraft_account_service_exceptions.MinecraftAccountApiException(
        e,
      );
    } on microsoft_auth_code_flow_exceptions.MicrosoftAuthCodeFlowException catch (
      e
    ) {
      throw minecraft_account_service_exceptions.MicrosoftAuthCodeFlowException(
        e,
      );
    } on minecraft_account_resolver_exceptions.MinecraftAccountResolverException catch (
      e
    ) {
      throw minecraft_account_service_exceptions.MinecraftAccountResolverException(
        e,
      );
    } on minecraft_account_refresher_exceptions.MinecraftAccountRefresherException catch (
      e
    ) {
      throw minecraft_account_service_exceptions.MinecraftAccountRefresherException(
        e,
      );
    }
  }

  Future<MinecraftLoginResult?> loginWithMicrosoftAuthCode({
    required MinecraftAuthProgressCallback onProgress,
    required AuthCodeLoginUrlAvailableCallback onAuthCodeLoginUrlAvailable,
    // The page content is not hardcoded for localization.
    required MicrosoftAuthCodeResponsePageVariants authCodeResponsePageVariants,
  }) async => _transformExceptions(() async {
    await microsoftOAuthFlowController.startAuthCodeServer();
    final tokenResponse = await microsoftOAuthFlowController
        .loginWithMicrosoftAuthCode(
          onProgress:
              (progress) => onProgress(switch (progress) {
                MicrosoftAuthCodeProgress.waitingForUserLogin =>
                  MinecraftAuthProgress.waitingForUserLogin,
                MicrosoftAuthCodeProgress.exchangingAuthCode =>
                  MinecraftAuthProgress.exchangingAuthCode,
              }),
          onAuthCodeLoginUrlAvailable: onAuthCodeLoginUrlAvailable,
          authCodeResponsePageVariants: authCodeResponsePageVariants,
        );
    if (tokenResponse == null) {
      return null;
    }

    return _resolveAndSave(
      tokenResponse: tokenResponse,
      onProgress: onProgress,
    );
  });

  Future<MinecraftDeviceCodeLoginResult> requestLoginWithMicrosoftDeviceCode({
    required MinecraftAuthProgressCallback onProgress,
    required UserDeviceCodeAvailableCallback onUserDeviceCodeAvailable,
  }) => _transformExceptions(() async {
    final (tokenResponse, closeReason) = await microsoftOAuthFlowController
        .requestLoginWithMicrosoftDeviceCode(
          onProgress:
              (progress) => onProgress(switch (progress) {
                MicrosoftDeviceCodeProgress.waitingForUserLogin =>
                  MinecraftAuthProgress.waitingForUserLogin,
              }),
          onUserDeviceCodeAvailable: onUserDeviceCodeAvailable,
        );
    if (tokenResponse == null) {
      return MinecraftDeviceCodeLoginResult(
        loginResult: null,
        closeReason: closeReason,
      );
    }

    final loginResult = await _resolveAndSave(
      tokenResponse: tokenResponse,
      onProgress: onProgress,
    );

    return MinecraftDeviceCodeLoginResult(
      loginResult: loginResult,
      closeReason: closeReason,
    );
  });

  Future<MinecraftLoginResult> _resolveAndSave({
    required MicrosoftOAuthTokenResponse tokenResponse,
    required MinecraftAuthProgressCallback onProgress,
  }) async {
    final account = await minecraftAccountResolver.resolve(
      oauthTokenResponse: tokenResponse,
      onProgress: (progress) => onProgress(_resolveToAuthProgress(progress)),
    );
    final accountExists = accountRepository.accountExists(account.id);
    if (accountExists) {
      await accountRepository.updateAccount(account);
    } else {
      await accountRepository.addAccount(account);
    }

    return MinecraftLoginResult(account: account, accountExists: accountExists);
  }

  // TODO: MinecraftAccountRefresher probably should not delegate to MinecraftAccountResolver directly??
  //  Also refreshMinecraftAccessTokenIfExpired should not depend on
  //  MicrosoftAuthApi and MinecraftAccountApi directly? Since thoes are also dependencies of MinecraftAccountResolver.
  MinecraftAuthProgress _resolveToAuthProgress(
    ResolveMinecraftAccountProgress progress,
  ) => switch (progress) {
    ResolveMinecraftAccountProgress.requestingXboxToken =>
      MinecraftAuthProgress.requestingXboxToken,
    ResolveMinecraftAccountProgress.requestingXstsToken =>
      MinecraftAuthProgress.requestingXstsToken,
    ResolveMinecraftAccountProgress.loggingIntoMinecraft =>
      MinecraftAuthProgress.loggingIntoMinecraft,
    ResolveMinecraftAccountProgress.checkingMinecraftJavaOwnership =>
      MinecraftAuthProgress.checkingMinecraftJavaOwnership,
    ResolveMinecraftAccountProgress.fetchingProfile =>
      MinecraftAuthProgress.fetchingProfile,
  };

  Future<bool> stopAuthCodeServerIfRunning() =>
      microsoftOAuthFlowController.stopAuthCodeServerIfRunning();

  bool cancelDeviceCodePollingTimer() =>
      microsoftOAuthFlowController.cancelDeviceCodePollingTimer();

  Future<MinecraftAccount> refreshMicrosoftAccount(
    MinecraftAccount account, {
    required MinecraftAuthProgressCallback onProgress,
  }) async => _transformExceptions(() async {
    try {
      final refreshedAccount = await minecraftAccountRefresher
          .refreshMicrosoftAccount(
            account,
            onRefreshProgress:
                (progress) => onProgress(switch (progress) {
                  RefreshMinecraftAccountProgress.refreshingMicrosoftTokens =>
                    MinecraftAuthProgress.refreshingMicrosoftTokens,
                }),
            onResolveAccountProgress:
                (progress) => onProgress(_resolveToAuthProgress(progress)),
          );

      await accountRepository.updateAccount(refreshedAccount);

      return refreshedAccount;
    } on minecraft_account_refresher_exceptions.InvalidMicrosoftRefreshTokenException catch (
      e
    ) {
      await accountRepository.updateAccount(e.updatedAccount);
      rethrow;
    }
  });
}

@immutable
class MinecraftLoginResult {
  const MinecraftLoginResult({
    required this.account,
    required this.accountExists,
  });

  final MinecraftAccount account;
  final bool accountExists;
}

@immutable
class MinecraftDeviceCodeLoginResult {
  const MinecraftDeviceCodeLoginResult({
    required this.loginResult,
    required this.closeReason,
  });

  final MinecraftLoginResult? loginResult;
  final DeviceCodeTimerCloseReason closeReason;
}

typedef MinecraftAuthProgressCallback =
    void Function(MinecraftAuthProgress progress);
