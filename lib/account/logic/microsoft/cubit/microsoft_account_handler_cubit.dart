import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../common/logic/utils.dart';
import '../../../data/minecraft_account/minecraft_account.dart';
import '../../account_cubit.dart';
import '../../account_manager/minecraft_account_manager.dart';
import '../../account_manager/minecraft_account_manager_exceptions.dart';
import '../../account_utils.dart';

part 'microsoft_account_handler_state.dart';

// Focused on Microsoft account operations, including login, skin upload,
// refresh, but doesn't store the accounts state, which is in AccountCubit.
class MicrosoftAccountHandlerCubit extends Cubit<MicrosoftAccountHandlerState> {
  MicrosoftAccountHandlerCubit({
    required this.minecraftAccountManager,
    required this.accountCubit,
  }) : super(const MicrosoftAccountHandlerState());

  final MinecraftAccountManager minecraftAccountManager;

  final AccountCubit accountCubit;

  Future<void> _handleErrors(
    Future<void> Function() run, {
    MicrosoftLoginStatus? microsoftLoginStatus,
    MicrosoftRefreshAccountStatus? microsoftRefreshAccountStatus,
  }) async {
    try {
      await run();
    } on AccountManagerException catch (e) {
      if (e is AccountManagerInvalidMicrosoftRefreshToken) {
        // TODO: We should not need this anymore due to AccountRepository, remove this when AccountCubit depends on AccountRepository. MicrosoftAccountHandlerCubit should not depend on AccountCubit directly.
        accountCubit.setAccounts(
          accountCubit.state.accounts.updateById(
            e.updatedAccount.id,
            (_) => e.updatedAccount,
          ),
        );
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
  }) => _handleErrors(() async {
    await minecraftAccountManager.startServer();
    final result = await minecraftAccountManager.loginWithMicrosoftAuthCode(
      onProgressUpdate:
          (newProgress, {authCodeLoginUrl}) => emit(
            state.copyWith(
              authProgress: newProgress,
              microsoftLoginStatus: MicrosoftLoginStatus.loading,
              authCodeLoginUrl: authCodeLoginUrl,
            ),
          ),
      authCodeResponsePageVariants: authCodeResponsePageVariants,
    );
    if (result == null) {
      // The user closed the login dialog without completing the login.
      // Closing the dialog will stop the server and cause this to be null.
      return;
    }

    accountCubit.emitByAccountResult(result);

    emit(
      state.copyWith(
        microsoftLoginStatus:
            result.hasUpdatedExistingAccount
                ? MicrosoftLoginStatus.successAccountUpdated
                : MicrosoftLoginStatus.successAccountAdded,
        recentAccount: result.newAccount,
      ),
    );

    // ignore: require_trailing_commas
  }, microsoftLoginStatus: MicrosoftLoginStatus.failure);

  /// Starts polling the device code status every 5 seconds (depends on the server)
  /// using a timer, the timer can be cancelled using [cancelDeviceCodePollingTimer].
  Future<void> requestLoginWithMicrosoftDeviceCode() => _handleErrors(() async {
    emit(
      state.copyWith(
        requestedDeviceCode: const Wrapped.value(null),
        deviceCodeStatus: DeviceCodeStatus.requestingCode,
      ),
    );
    final (result, closeReason) = await minecraftAccountManager
        .requestLoginWithMicrosoftDeviceCode(
          onProgressUpdate:
              (newProgress) => emit(
                state.copyWith(
                  authProgress: newProgress,
                  microsoftLoginStatus:
                      newProgress == MicrosoftAuthProgress.waitingForUserLogin
                          ? null
                          : MicrosoftLoginStatus.loading,
                ),
              ),
          onDeviceCodeAvailable:
              (deviceCode) => emit(
                state.copyWith(
                  requestedDeviceCode: Wrapped.value(deviceCode),
                  deviceCodeStatus: DeviceCodeStatus.polling,
                ),
              ),
        );

    if (result == null) {
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

    accountCubit.emitByAccountResult(result);

    emit(
      state.copyWith(
        deviceCodeStatus: DeviceCodeStatus.idle,
        requestedDeviceCode: const Wrapped.value(null),
        recentAccount: result.newAccount,
        microsoftLoginStatus:
            result.hasUpdatedExistingAccount
                ? MicrosoftLoginStatus.successAccountUpdated
                : MicrosoftLoginStatus.successAccountAdded,
      ),
    );

    // ignore: require_trailing_commas
  }, microsoftLoginStatus: MicrosoftLoginStatus.failure);

  void cancelDeviceCodePollingTimer() {
    final cancelled = minecraftAccountManager.cancelDeviceCodePollingTimer();
    if (cancelled) {
      emit(state.copyWith(requestedDeviceCode: const Wrapped.value(null)));
    }
  }

  Future<void> stopServerIfRunning() async {
    if (await minecraftAccountManager.stopServerIfRunning()) {
      emit(
        state.copyWith(
          microsoftLoginStatus: MicrosoftLoginStatus.cancelled,
          authProgress: null,
        ),
      );
    }
  }

  Future<void> refreshMicrosoftAccount(MinecraftAccount account) =>
      _handleErrors(() async {
        final result = await minecraftAccountManager.refreshMicrosoftAccount(
          account,
          onProgressUpdate:
              (newProgress) => emit(
                state.copyWith(
                  microsoftRefreshAccountStatus:
                      MicrosoftRefreshAccountStatus.loading,
                  authProgress: newProgress,
                ),
              ),
        );

        accountCubit.emitByAccountResult(result);

        emit(
          state.copyWith(
            microsoftRefreshAccountStatus:
                MicrosoftRefreshAccountStatus.success,
            recentAccount: result.newAccount,
          ),
        );

        // ignore: require_trailing_commas
      }, microsoftRefreshAccountStatus: MicrosoftRefreshAccountStatus.failure);

  // Reset to avoid repeated reactions to the same status after a successful login
  void resetLoginStatus() {
    emit(state.copyWith(microsoftLoginStatus: MicrosoftLoginStatus.initial));
  }

  void resetRefreshStatus() {
    emit(
      state.copyWith(
        microsoftRefreshAccountStatus: MicrosoftRefreshAccountStatus.initial,
      ),
    );
  }

  @override
  Future<void> close() async {
    await minecraftAccountManager.stopServerIfRunning();
    minecraftAccountManager.cancelDeviceCodePollingTimer();
    return super.close();
  }
}
