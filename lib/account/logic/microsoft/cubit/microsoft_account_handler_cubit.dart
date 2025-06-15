import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../common/logic/utils.dart';
import '../../../data/minecraft_account/minecraft_account.dart';
import '../../account_cubit/account_cubit.dart';
import '../auth_flows/auth_code/microsoft_auth_code_flow.dart';
import '../auth_flows/device_code/microsoft_device_code_flow.dart';
import '../minecraft/account_refresher/minecraft_account_refresher_exceptions.dart'
    as minecraft_account_refresher_exceptions;
import '../minecraft/account_service/minecraft_account_service.dart';
import '../minecraft/account_service/minecraft_account_service_exceptions.dart'
    as minecraft_account_service_exceptions;
import '../minecraft/account_service/minecraft_account_service_exceptions.dart';
import '../minecraft/account_service/minecraft_full_auth_progress.dart';

part 'microsoft_account_handler_state.dart';

class MicrosoftAccountHandlerCubit extends Cubit<MicrosoftAccountHandlerState> {
  MicrosoftAccountHandlerCubit({
    required this.minecraftAccountService,
    required this.accountCubit,
  }) : super(const MicrosoftAccountHandlerState());

  final MinecraftAccountService minecraftAccountService;
  final AccountCubit accountCubit;

  Future<void> _handleFailures(
    Future<void> Function() run, {
    MicrosoftLoginStatus? microsoftLoginStatus,
    MicrosoftRefreshAccountStatus? microsoftRefreshAccountStatus,
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
          // TODO: If Account refreshed moved into a new cubit, then extract this handling from it
          // TODO: Test this change manually NEED_REAL_TEST_CONFIRMATION
          // TODO: We should not need this anymore due to AccountRepository, remove this when AccountCubit depends on AccountRepository. MicrosoftAccountHandlerCubit should not depend on AccountCubit directly.
          accountCubit.handleExternalAccountChange(
            account: refresherException.updatedAccount,
          );
        }
      }

      emit(
        state.copyWith(
          microsoftLoginStatus: microsoftLoginStatus,
          microsoftRefreshAccountStatus: microsoftRefreshAccountStatus,
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
          (newProgress) => emit(
            state.copyWith(
              authProgress: newProgress,
              microsoftLoginStatus: MicrosoftLoginStatus.loading,
            ),
          ),
      onAuthCodeLoginUrlAvailable: (authCodeLoginUrl) {
        emit(
          state.copyWith(
            microsoftLoginStatus: MicrosoftLoginStatus.loading,
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
        microsoftLoginStatus:
            hasUpdatedExistingAccount
                ? MicrosoftLoginStatus.successAccountUpdated
                : MicrosoftLoginStatus.successAccountAdded,
        recentAccount: account,
      ),
    );
  }, microsoftLoginStatus: MicrosoftLoginStatus.failure);

  /// Starts polling the device code status every 5 seconds (depends on the server)
  /// using a timer, the timer can be cancelled using [cancelDeviceCodePollingTimer].
  Future<void>
  requestLoginWithMicrosoftDeviceCode() => _handleFailures(() async {
    emit(
      state.copyWith(
        requestedDeviceCode: const Wrapped.value(null),
        deviceCodeStatus: DeviceCodeStatus.requestingCode,
      ),
    );
    final deviceCodeResult = await minecraftAccountService
        .requestLoginWithMicrosoftDeviceCode(
          onProgress:
              (progress) => emit(
                state.copyWith(
                  authProgress: progress,
                  microsoftLoginStatus:
                      // Avoid showing loading, user may log in via auth or device code.
                      (progress.deviceCodeProgress!.progress ==
                              MicrosoftDeviceCodeProgress.waitingForUserLogin)
                          // TODO: Maybe set to MicrosoftLoginStatus.initial instead?
                          ? null
                          : MicrosoftLoginStatus.loading,
                ),
              ),
          onUserDeviceCodeAvailable:
              (deviceCode) => emit(
                state.copyWith(
                  requestedDeviceCode: Wrapped.value(deviceCode),
                  deviceCodeStatus: DeviceCodeStatus.polling,
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
            DeviceCodeTimerCloseReason.codeExpired => DeviceCodeStatus.expired,
            DeviceCodeTimerCloseReason.declined => DeviceCodeStatus.declined,
            DeviceCodeTimerCloseReason.approved => DeviceCodeStatus.idle,
            DeviceCodeTimerCloseReason.cancelledByUser => DeviceCodeStatus.idle,
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
        deviceCodeStatus: DeviceCodeStatus.idle,
        requestedDeviceCode: const Wrapped.value(null),
        recentAccount: account,
        microsoftLoginStatus:
            accountExists
                ? MicrosoftLoginStatus.successAccountUpdated
                : MicrosoftLoginStatus.successAccountAdded,
      ),
    );
  }, microsoftLoginStatus: MicrosoftLoginStatus.failure);

  void cancelDeviceCodePollingTimer() {
    final cancelled = minecraftAccountService.cancelDeviceCodePollingTimer();
    if (cancelled) {
      emit(state.copyWith(requestedDeviceCode: const Wrapped.value(null)));
    }
  }

  Future<void> stopServerIfRunning() async {
    final stopped = await minecraftAccountService.stopAuthCodeServerIfRunning();
    if (stopped) {
      emit(
        state.copyWith(
          microsoftLoginStatus: MicrosoftLoginStatus.cancelled,
          authProgress: null,
        ),
      );
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
                      microsoftRefreshAccountStatus:
                          MicrosoftRefreshAccountStatus.loading,
                      authProgress: progress,
                    ),
                  ),
            );

        accountCubit.handleExternalAccountChange(account: refreshedAccount);

        emit(
          state.copyWith(
            microsoftRefreshAccountStatus:
                MicrosoftRefreshAccountStatus.success,
            recentAccount: refreshedAccount,
          ),
        );
      }, microsoftRefreshAccountStatus: MicrosoftRefreshAccountStatus.failure);

  // Reset to avoid repeated reactions to the same status after a successful login
  void resetLoginStatus() =>
      emit(state.copyWith(microsoftLoginStatus: MicrosoftLoginStatus.initial));

  void resetRefreshStatus() => emit(
    state.copyWith(
      microsoftRefreshAccountStatus: MicrosoftRefreshAccountStatus.initial,
    ),
  );

  @override
  Future<void> close() async {
    await minecraftAccountService.stopAuthCodeServerIfRunning();
    minecraftAccountService.cancelDeviceCodePollingTimer();
    return super.close();
  }
}
