/// @docImport '../../microsoft_oauth_flow_controller.dart';
/// @docImport '../auth_code/microsoft_auth_code_flow.dart';
library;

import 'package:clock/clock.dart';
import 'package:meta/meta.dart';

import '../../../../../common/logic/app_logger.dart';
import '../../../../../common/logic/utils.dart';
import '../../../../data/microsoft_auth_api/auth_flows/microsoft_device_code_flow_api.dart';
import '../../../../data/microsoft_auth_api/microsoft_auth_api.dart';
import 'async_timer.dart';

/// Handles Microsoft OAuth device code flow (not specific to Minecraft).
///
/// Communicates with Microsoft API to obtain a device code that the user
/// must open on Microsoft’s site to authenticate.
///
/// While the user completes authentication, it polls the device code status
/// using a timer, and upon successful authentication,
/// retrieves Microsoft OAuth access and refresh tokens.
///
/// See also:
///
/// * [MicrosoftAuthCodeFlow], for Microsoft auth code authentication.
/// * [MicrosoftOAuthFlowController], that manages both [MicrosoftAuthCodeFlow] and [MicrosoftDeviceCodeFlow].
class MicrosoftDeviceCodeFlow {
  MicrosoftDeviceCodeFlow({required this.microsoftAuthApi});

  @visibleForTesting
  final MicrosoftAuthApi microsoftAuthApi;

  /// Timer that periodically checks the device code status during login.
  /// Set when [run] is called, and cleared
  /// after success or code expiration.
  @visibleForTesting
  AsyncTimer<MicrosoftDeviceCodeApproved?>? pollingTimer;

  bool get isPollingTimerActive => pollingTimer?.isActive ?? false;

  /// A flag is used to cancel the timer when [cancelPollingTimer] is
  /// called before [pollingTimer] is initialized.
  /// Once [pollingTimer] is initialized, this flag
  /// will be used inside the timer callback to cancel it.
  @visibleForTesting
  bool requestCancelPollingTimer = false;

  // Cancels the polling timer if active.
  // Returns whether the timer has been cancelled and was active.
  bool cancelPollingTimer([MicrosoftDeviceCodeApproved? result]) {
    final isActive = isPollingTimerActive;
    pollingTimer?.cancel(result);
    pollingTimer = null;
    requestCancelPollingTimer = true;
    return isActive;
  }

  /// Requests a device code for login and keeps polling the device code status
  /// until the code expires or login is successful.
  ///
  /// Returns null when the device code has expired or the timer
  /// has been cancelled (e.g., UI dialog is closed).
  Future<DeviceCodeLoginResult> run({
    required DeviceCodeProgressCallback onProgress,
    required UserDeviceCodeAvailableCallback onUserDeviceCodeAvailable,
  }) async {
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
    requestCancelPollingTimer = false;

    final deviceCodeResponse = await microsoftAuthApi.requestDeviceCode();
    final deviceCodeExpiresAt = expiresInToExpiresAt(
      deviceCodeResponse.expiresIn,
    );

    onUserDeviceCodeAvailable(deviceCodeResponse.userCode);
    onProgress(MicrosoftDeviceCodeProgress.waitingForUserLogin);

    var closeReason = DeviceCodeTimerCloseReason.cancelledByUser;

    void cancelTimerOnExpiration() {
      closeReason = DeviceCodeTimerCloseReason.codeExpired;
      cancelPollingTimer();
    }

    pollingTimer = AsyncTimer.periodic(
      Duration(
        seconds:
            deviceCodeResponse
                .interval, // This is probably 5 seconds but should not be hardcoded
      ),
      () async {
        if (requestCancelPollingTimer) {
          // Fixes an issue where the timer is requested to be canceled
          // before it has started, due to awaiting a future call. Which
          // will cause the timer to continue running.
          cancelPollingTimer();

          // After this call, requestCancelPollingTimer is remain true
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
            cancelPollingTimer(checkDeviceCodeResult);
          case MicrosoftDeviceCodeDeclined():
            closeReason = DeviceCodeTimerCloseReason.declined;
            cancelPollingTimer();
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
      if (isPollingTimerActive) {
        // Fallback to ensure the timer is stopped and completer is completed
        // in case something goes wrong.

        cancelTimerOnExpiration();
      }
    });

    final deviceCodeSuccess = await pollingTimer!.awaitTimer();

    assert(
      !isPollingTimerActive,
      'The device code check timer should be cancelled at this point, this is likely a bug.',
    );

    if (pollingTimer != null) {
      AppLogger.w(
        'This is likely a bug, the timer should be cancelled at this point',
      );
      cancelPollingTimer();
    }

    // Response of exchanging the device code.
    final tokenResponse = deviceCodeSuccess?.response;
    if (tokenResponse == null) {
      // Device code has been expired or the timer is cancelled.
      return (null, closeReason);
    }

    return (tokenResponse, closeReason);
  }
}

enum DeviceCodeTimerCloseReason {
  codeExpired,
  approved,
  declined,
  cancelledByUser,
}

enum MicrosoftDeviceCodeProgress { waitingForUserLogin }

typedef DeviceCodeProgressCallback =
    void Function(MicrosoftDeviceCodeProgress progress);

typedef UserDeviceCodeAvailableCallback = void Function(String userDeviceCode);

typedef DeviceCodeLoginResult =
    (MicrosoftOAuthTokenResponse?, DeviceCodeTimerCloseReason);
