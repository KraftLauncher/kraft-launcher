import 'package:meta/meta.dart';

import '../../../../common/logic/json.dart';
import '../microsoft_auth_api.dart';

@immutable
class MicrosoftRequestDeviceCodeResponse {
  const MicrosoftRequestDeviceCodeResponse({
    required this.userCode,
    required this.deviceCode,
    required this.expiresIn,
    required this.interval,
  });

  factory MicrosoftRequestDeviceCodeResponse.fromJson(JsonObject json) =>
      MicrosoftRequestDeviceCodeResponse(
        userCode: json['user_code']! as String,
        deviceCode: json['device_code']! as String,
        expiresIn: json['expires_in']! as int,
        interval: json['interval']! as int,
      );

  final String userCode;
  final String deviceCode;
  final int expiresIn;
  final int interval;

  @override
  String toString() =>
      'MicrosoftRequestDeviceCodeResponse(userCode: $userCode, deviceCode: $deviceCode, expiresIn: $expiresIn, interval: $interval)';
}

@immutable
sealed class MicrosoftCheckDeviceCodeStatusResult {
  const MicrosoftCheckDeviceCodeStatusResult();

  factory MicrosoftCheckDeviceCodeStatusResult.approved(
    MicrosoftOauthTokenExchangeResponse response,
  ) => MicrosoftDeviceCodeApproved(response: response);
  factory MicrosoftCheckDeviceCodeStatusResult.declined() =>
      const MicrosoftDeviceCodeDeclined();
  factory MicrosoftCheckDeviceCodeStatusResult.expired() =>
      const MicrosoftDeviceCodeExpired();
  factory MicrosoftCheckDeviceCodeStatusResult.authorizationPending() =>
      const MicrosoftDeviceCodeAuthorizationPending();
}

class MicrosoftDeviceCodeApproved extends MicrosoftCheckDeviceCodeStatusResult {
  const MicrosoftDeviceCodeApproved({required this.response});

  final MicrosoftOauthTokenExchangeResponse response;
}

class MicrosoftDeviceCodeDeclined extends MicrosoftCheckDeviceCodeStatusResult {
  const MicrosoftDeviceCodeDeclined();
}

class MicrosoftDeviceCodeAuthorizationPending
    extends MicrosoftCheckDeviceCodeStatusResult {
  const MicrosoftDeviceCodeAuthorizationPending();
}

class MicrosoftDeviceCodeExpired extends MicrosoftCheckDeviceCodeStatusResult {
  const MicrosoftDeviceCodeExpired();
}

abstract class MicrosoftDeviceCodeFlowApi {
  Future<MicrosoftRequestDeviceCodeResponse> requestDeviceCode();

  Future<MicrosoftCheckDeviceCodeStatusResult> checkDeviceCodeStatus(
    MicrosoftRequestDeviceCodeResponse deviceCodeResponse,
  );
}
