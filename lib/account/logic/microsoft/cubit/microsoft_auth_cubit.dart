import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../common/logic/utils.dart';
import '../../../data/minecraft_account/minecraft_account.dart';
import '../../account_cubit/account_cubit.dart';
import '../../platform_secure_storage_support.dart';
import '../auth_flows/auth_code/microsoft_auth_code_flow.dart';
import '../auth_flows/device_code/microsoft_device_code_flow.dart';
import '../minecraft/account_refresher/minecraft_account_refresher_exceptions.dart'
    as minecraft_account_refresher_exceptions;
import '../minecraft/account_service/minecraft_account_service.dart';
import '../minecraft/account_service/minecraft_account_service_exceptions.dart'
    as minecraft_account_service_exceptions;
import '../minecraft/account_service/minecraft_account_service_exceptions.dart';

part 'microsoft_auth_state.dart';

class MicrosoftAuthCubit extends Cubit<MicrosoftAuthState> {
  MicrosoftAuthCubit({
    required this.minecraftAccountService,
    required this.accountCubit,
    required this.secureStorageSupport,
  }) : super(const MicrosoftAuthState()) {
    secureStorageSupport.isSupported().then(
      (value) => emit(state.copyWith(supportsSecureStorage: value)),
    );
  }

  final MinecraftAccountService minecraftAccountService;
  final AccountCubit accountCubit;
  final PlatformSecureStorageSupport secureStorageSupport;

  Future<void> _handleFailures(
    Future<void> Function() run, {
    MicrosoftLoginStatus? loginStatus,
    MicrosoftRefreshAccountStatus? refreshStatus,
  }) async {
    try {
      await run();
    } on minecraft_account_service_exceptions.MinecraftAccountServiceException catch (
      e
    ) {
      if (e
          is minecraft_account_service_exceptions.MinecraftAccountRefresherException) {
        final refresherException = e.exception;
        if (refresherException
            is minecraft_account_refresher_exceptions.InvalidMicrosoftRefreshTokenException) {
          // TODO: We should not need this anymore due to AccountRepository, remove this when AccountCubit depends on AccountRepository. MicrosoftAuthCubit should not depend on AccountCubit directly.
          accountCubit.handleExternalAccountChange(
            account: refresherException.updatedAccount,
          );
        }
      }

      emit(
        state.copyWith(
          loginStatus: loginStatus,
          refreshStatus: refreshStatus,
          exception: e,
        ),
      );
    }
  }

  Future<void> loginWithMicrosoftAuthCode({
    // The page content is not hardcoded for localization.
    required MicrosoftAuthCodeResponsePageVariants authCodeResponsePageVariants,
  }) => _handleFailures(() async {
    final (result) = await minecraftAccountService.loginWithMicrosoftAuthCode(
      onProgress:
          (progress) => emit(
            state.copyWith(
              loginProgress: progress,
              loginStatus: MicrosoftLoginStatus.loading,
              authFlow: MicrosoftAuthFlow.authCode,
            ),
          ),
      onAuthCodeLoginUrlAvailable: (authCodeLoginUrl) {
        emit(
          state.copyWith(
            loginStatus: MicrosoftLoginStatus.loading,
            authCodeLoginUrl: authCodeLoginUrl,
          ),
        );

        launchUrl(Uri.parse(authCodeLoginUrl));
      },
      authCodeResponsePageVariants: authCodeResponsePageVariants,
    );
    if (result == null) {
      // The user closed the login dialog without completing the login.
      // Closing the dialog will stop the server and cause this to be null.
      return;
    }
    final (account, hasUpdatedExistingAccount) = (
      result.account,
      result.accountExists,
    );

    accountCubit.handleExternalAccountChange(account: account);

    emit(
      state.copyWith(
        loginStatus:
            hasUpdatedExistingAccount
                ? MicrosoftLoginStatus.successRefreshedExisting
                : MicrosoftLoginStatus.successAddedNew,
        recentAccount: account,
      ),
    );
  }, loginStatus: MicrosoftLoginStatus.failure);

  /// Starts polling the device code status every 5 seconds (depends on the server)
  /// using a timer, the timer can be cancelled using [cancelDeviceCodePollingTimer].
  Future<void>
  requestLoginWithMicrosoftDeviceCode() => _handleFailures(() async {
    emit(
      state.copyWith(
        requestedDeviceCode: const Wrapped.value(null),
        deviceCodeStatus: MicrosoftDeviceCodeStatus.requestingCode,
        authFlow: MicrosoftAuthFlow.deviceCode,
      ),
    );
    final deviceCodeResult = await minecraftAccountService
        .requestLoginWithMicrosoftDeviceCode(
          onProgress:
              (progress) => emit(
                state.copyWith(
                  loginProgress: progress,
                  loginStatus:
                      // Avoid showing loading. Device code is requested on login dialog open,
                      // and the user may use auth/device code to login.
                      (progress == MinecraftAuthProgress.waitingForUserLogin)
                          ? null
                          : MicrosoftLoginStatus.loading,
                ),
              ),
          onUserDeviceCodeAvailable:
              (deviceCode) => emit(
                state.copyWith(
                  requestedDeviceCode: Wrapped.value(deviceCode),
                  deviceCodeStatus: MicrosoftDeviceCodeStatus.polling,
                ),
              ),
        );

    final (accountResult, closeReason) = (
      deviceCodeResult.loginResult,
      deviceCodeResult.closeReason,
    );

    if (accountResult == null) {
      emit(
        state.copyWith(
          deviceCodeStatus: switch (closeReason) {
            DeviceCodeTimerCloseReason.codeExpired =>
              MicrosoftDeviceCodeStatus.expired,
            DeviceCodeTimerCloseReason.declined =>
              MicrosoftDeviceCodeStatus.declined,
            DeviceCodeTimerCloseReason.approved =>
              MicrosoftDeviceCodeStatus.idle,
            DeviceCodeTimerCloseReason.cancelledByUser =>
              MicrosoftDeviceCodeStatus.idle,
          },
          requestedDeviceCode: const Wrapped.value(null),
        ),
      );
      return;
    }

    final (account, accountExists) = (
      accountResult.account,
      accountResult.accountExists,
    );

    accountCubit.handleExternalAccountChange(account: accountResult.account);

    emit(
      state.copyWith(
        deviceCodeStatus: MicrosoftDeviceCodeStatus.idle,
        requestedDeviceCode: const Wrapped.value(null),
        recentAccount: account,
        loginStatus:
            accountExists
                ? MicrosoftLoginStatus.successRefreshedExisting
                : MicrosoftLoginStatus.successAddedNew,
      ),
    );
  }, loginStatus: MicrosoftLoginStatus.failure);

  void cancelDeviceCodePollingTimer() {
    final cancelled = minecraftAccountService.cancelDeviceCodePollingTimer();
    if (cancelled) {
      emit(
        state.copyWith(
          requestedDeviceCode: const Wrapped.value(null),
          loginStatus: MicrosoftLoginStatus.cancelled,
        ),
      );
    }
  }

  Future<void> stopAuthCodeServerIfRunning() async {
    final stopped = await minecraftAccountService.stopAuthCodeServerIfRunning();
    if (stopped) {
      emit(state.copyWith(loginStatus: MicrosoftLoginStatus.cancelled));
    }
  }

  Future<void> refreshMicrosoftAccount(MinecraftAccount account) =>
      _handleFailures(() async {
        final refreshedAccount = await minecraftAccountService
            .refreshMicrosoftAccount(
              account,
              onProgress:
                  (progress) => emit(
                    state.copyWith(
                      refreshStatus: MicrosoftRefreshAccountStatus.loading,
                      refreshAccountProgress: progress,
                    ),
                  ),
            );

        accountCubit.handleExternalAccountChange(account: refreshedAccount);

        emit(
          state.copyWith(
            refreshStatus: MicrosoftRefreshAccountStatus.success,
            recentAccount: refreshedAccount,
          ),
        );
      }, refreshStatus: MicrosoftRefreshAccountStatus.failure);

  // Reset to prevent BlocListener from reacting again to a successful login,
  // which could cause a bug when opening the login dialog again.
  void resetLoginStatus() =>
      emit(state.copyWith(loginStatus: MicrosoftLoginStatus.initial));

  @override
  Future<void> close() async {
    await minecraftAccountService.stopAuthCodeServerIfRunning();
    minecraftAccountService.cancelDeviceCodePollingTimer();
    return super.close();
  }
}
