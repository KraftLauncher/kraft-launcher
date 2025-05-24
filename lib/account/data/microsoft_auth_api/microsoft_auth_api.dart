import 'package:meta/meta.dart';

import '../../../common/logic/json.dart';
import '../minecraft_api/minecraft_api.dart';
import 'auth_methods/microsoft_auth_code_flow.dart';
import 'auth_methods/microsoft_device_code_flow.dart';

// The success response when exchanging the auth code or device code for Microsoft tokens.
@immutable
class MicrosoftOauthTokenExchangeResponse {
  const MicrosoftOauthTokenExchangeResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory MicrosoftOauthTokenExchangeResponse.fromJson(JsonObject json) =>
      MicrosoftOauthTokenExchangeResponse(
        accessToken: json['access_token']! as String,
        refreshToken: json['refresh_token']! as String,
        expiresIn: json['expires_in']! as int,
      );

  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  @override
  String toString() =>
      'MicrosoftOauthTokenExchangeResponse(accessToken: $accessToken, refreshToken: $refreshToken, expiresIn: $expiresIn)';
}

@immutable
class XboxLiveAuthTokenResponse {
  const XboxLiveAuthTokenResponse({
    required this.xboxToken,
    required this.userHash,
  });

  factory XboxLiveAuthTokenResponse.fromJson(JsonObject json) =>
      XboxLiveAuthTokenResponse(
        xboxToken: json['Token']! as String,
        userHash: () {
          final displayClaims = json['DisplayClaims']! as JsonObject;
          final xui =
              (displayClaims['xui']! as List<dynamic>).cast<JsonObject>();
          final uhs = xui.first['uhs']! as String;
          return uhs;
        }(),
      );

  final String xboxToken;
  final String userHash;

  @override
  String toString() =>
      'XboxLiveAuthTokenResponse(xboxToken: $xboxToken, userHash: $userHash)';
}

/// See also:
///  * https://minecraft.wiki/w/Microsoft_authentication
///  * [MinecraftApi]
abstract class MicrosoftAuthApi
    implements MicrosoftAuthCodeFlow, MicrosoftDeviceCodeFlow {
  // TODO: It's probably better to require the token only instead of the full response to avoid confusion, make the same change to MinecraftApi
  Future<XboxLiveAuthTokenResponse> requestXboxLiveToken(
    MicrosoftOauthTokenExchangeResponse microsoftOauthToken,
  );
  Future<XboxLiveAuthTokenResponse> requestXSTSToken(
    XboxLiveAuthTokenResponse xboxLiveToken,
  );

  Future<MicrosoftOauthTokenExchangeResponse> getNewTokensFromRefreshToken(
    String microsoftRefreshToken,
  );
}
