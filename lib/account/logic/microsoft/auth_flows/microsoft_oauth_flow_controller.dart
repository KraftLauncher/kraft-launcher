import 'package:kraft_launcher/account/data/microsoft_auth_api/microsoft_auth_api.dart';
import 'package:kraft_launcher/account/logic/microsoft/auth_flows/auth_code/microsoft_auth_code_flow.dart';
import 'package:kraft_launcher/account/logic/microsoft/auth_flows/device_code/microsoft_device_code_flow.dart';

/// Manages Microsoft OAuth authentication supporting both
/// authorization code and device code flows.
///
/// Cancels device code polling when initiating the
/// authorization code flow to avoid concurrent authentication attempts.
class MicrosoftOAuthFlowController {
  MicrosoftOAuthFlowController({
    required MicrosoftAuthCodeFlow microsoftAuthCodeFlow,
    required MicrosoftDeviceCodeFlow microsoftDeviceCodeFlow,
  }) : _microsoftDeviceCodeFlow = microsoftDeviceCodeFlow,
       _microsoftAuthCodeFlow = microsoftAuthCodeFlow;

  final MicrosoftAuthCodeFlow _microsoftAuthCodeFlow;
  final MicrosoftDeviceCodeFlow _microsoftDeviceCodeFlow;

  Future<MicrosoftOAuthTokenResponse?> loginWithMicrosoftAuthCode({
    required AuthCodeProgressCallback onProgress,
    required AuthCodeLoginUrlAvailableCallback onAuthCodeLoginUrlAvailable,
    // The page content is not hardcoded for localization.
    required MicrosoftAuthCodeResponsePageVariants authCodeResponsePageVariants,
  }) {
    _microsoftDeviceCodeFlow.cancelPollingTimer();
    return _microsoftAuthCodeFlow.run(
      onProgress: onProgress,
      onAuthCodeLoginUrlAvailable: onAuthCodeLoginUrlAvailable,
      authCodeResponsePageVariants: authCodeResponsePageVariants,
    );
  }

  Future<DeviceCodeLoginResult> requestLoginWithMicrosoftDeviceCode({
    required DeviceCodeProgressCallback onProgress,
    required UserDeviceCodeAvailableCallback onUserDeviceCodeAvailable,
  }) => _microsoftDeviceCodeFlow.run(
    onProgress: onProgress,
    onUserDeviceCodeAvailable: onUserDeviceCodeAvailable,
  );

  Future<bool> closeAuthCodeServer() async =>
      _microsoftAuthCodeFlow.closeServer();

  bool cancelDeviceCodePollingTimer() =>
      _microsoftDeviceCodeFlow.cancelPollingTimer();
}
