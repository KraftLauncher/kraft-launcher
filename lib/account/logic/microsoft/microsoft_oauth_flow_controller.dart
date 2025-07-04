import 'package:kraft_launcher/account/data/microsoft_auth_api/microsoft_auth_api.dart';
import 'package:kraft_launcher/account/logic/microsoft/auth_flows/auth_code/microsoft_auth_code_flow.dart';
import 'package:kraft_launcher/account/logic/microsoft/auth_flows/device_code/microsoft_device_code_flow.dart';
import 'package:meta/meta.dart';

// TODO: Move this file to auth_flows directory.

/// Manages Microsoft OAuth authentication supporting both
/// authorization code and device code flows.
///
/// Cancels device code polling when initiating the
/// authorization code flow to avoid concurrent authentication attempts.
class MicrosoftOAuthFlowController {
  MicrosoftOAuthFlowController({
    required this.microsoftAuthCodeFlow,
    required this.microsoftDeviceCodeFlow,
  });

  @visibleForTesting
  final MicrosoftAuthCodeFlow microsoftAuthCodeFlow;
  @visibleForTesting
  final MicrosoftDeviceCodeFlow microsoftDeviceCodeFlow;

  Future<MicrosoftOAuthTokenResponse?> loginWithMicrosoftAuthCode({
    required AuthCodeProgressCallback onProgress,
    required AuthCodeLoginUrlAvailableCallback onAuthCodeLoginUrlAvailable,
    // The page content is not hardcoded for localization.
    required MicrosoftAuthCodeResponsePageVariants authCodeResponsePageVariants,
  }) {
    microsoftDeviceCodeFlow.cancelPollingTimer();
    return microsoftAuthCodeFlow.run(
      onProgress: onProgress,
      onAuthCodeLoginUrlAvailable: onAuthCodeLoginUrlAvailable,
      authCodeResponsePageVariants: authCodeResponsePageVariants,
    );
  }

  Future<DeviceCodeLoginResult> requestLoginWithMicrosoftDeviceCode({
    required DeviceCodeProgressCallback onProgress,
    required UserDeviceCodeAvailableCallback onUserDeviceCodeAvailable,
  }) => microsoftDeviceCodeFlow.run(
    onProgress: onProgress,
    onUserDeviceCodeAvailable: onUserDeviceCodeAvailable,
  );

  Future<void> startAuthCodeServer() => microsoftAuthCodeFlow.startServer();

  Future<bool> stopAuthCodeServerIfRunning() async =>
      microsoftAuthCodeFlow.stopServerIfRunning();

  bool cancelDeviceCodePollingTimer() =>
      microsoftDeviceCodeFlow.cancelPollingTimer();
}
