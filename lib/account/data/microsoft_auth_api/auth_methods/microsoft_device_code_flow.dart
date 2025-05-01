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
}

class MicrosoftDeviceCodeSuccess extends MicrosoftCheckDeviceCodeStatusResult {
  const MicrosoftDeviceCodeSuccess({required this.response});

  final MicrosoftOauthTokenExchangeResponse response;
}

class MicrosoftDeviceCodeExpired extends MicrosoftCheckDeviceCodeStatusResult {
  const MicrosoftDeviceCodeExpired();
}

class MicrosoftDeviceCodeAuthorizationPending
    extends MicrosoftCheckDeviceCodeStatusResult {
  const MicrosoftDeviceCodeAuthorizationPending();
}

abstract class MicrosoftDeviceCodeFlow {
  Future<MicrosoftRequestDeviceCodeResponse> requestDeviceCode();

  Future<MicrosoftCheckDeviceCodeStatusResult> checkDeviceCodeStatus(
    MicrosoftRequestDeviceCodeResponse deviceCodeResponse,
  );
}
