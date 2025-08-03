import 'package:minecraft_services_client/src/minecraft_services_api_client.dart';
import 'package:minecraft_services_client/src/models/minecraft_entitlements_response.dart';
import 'package:minecraft_services_client/src/models/minecraft_error_response.dart';
import 'package:minecraft_services_client/src/models/minecraft_login_response.dart';
import 'package:minecraft_services_client/src/models/profile/minecraft_profile_response.dart';
import 'package:minecraft_services_client/src/models/profile/skin/enums/minecraft_skin_variant.dart';
import 'package:safe_http/safe_http.dart';

final class HttpMinecraftServicesApiClient
    implements MinecraftServicesApiClient {
  HttpMinecraftServicesApiClient({
    required JsonApiClient jsonApiClient,
    String? host,
  }) : _jsonApiClient = jsonApiClient,
       _host = host ?? MinecraftServicesApiClient.baseUrlHost;

  final JsonApiClient _jsonApiClient;
  final String _host;

  @override
  MinecraftApiResultFuture<MinecraftLoginResponse> authenticateWithXbox({
    required String xstsToken,
    required String xstsUserHash,
  }) => _jsonApiClient.post(
    Uri.https(_host, 'authentication/login_with_xbox'),
    body: {'identityToken': 'XBL3.0 x=$xstsUserHash;$xstsToken'},
    isJsonBody: true,
    deserializeSuccess: (response) =>
        MinecraftLoginResponse.fromJson(response.body),
    deserializeClientFailure: (response) =>
        MinecraftErrorResponse.fromJson(response.body),
  );

  @override
  MinecraftApiResultFuture<MinecraftEntitlementsResponse> fetchEntitlements({
    required String accessToken,
  }) => _jsonApiClient.get(
    Uri.https(_host, 'entitlements/mcstore'),
    headers: _buildAuthorizationHeader(accessToken),
    deserializeSuccess: (response) =>
        MinecraftEntitlementsResponse.fromJson(response.body),
    deserializeClientFailure: (response) =>
        MinecraftErrorResponse.fromJson(response.body),
  );

  @override
  MinecraftApiResultFuture<MinecraftProfileResponse> fetchProfile({
    required String accessToken,
  }) => _jsonApiClient.get(
    Uri.https(_host, 'minecraft/profile'),
    headers: _buildAuthorizationHeader(accessToken),
    deserializeSuccess: (response) =>
        MinecraftProfileResponse.fromJson(response.body),
    deserializeClientFailure: (response) =>
        MinecraftErrorResponse.fromJson(response.body),
  );

  @override
  MinecraftApiResultFuture<MinecraftProfileResponse> uploadSkin({
    required String accessToken,
    required MultipartFile skinFile,
    required MinecraftSkinVariant variant,
  }) => _jsonApiClient.post(
    Uri.https(_host, 'minecraft/profile/skins'),
    headers: _buildAuthorizationHeader(accessToken),
    body: MultipartBody(
      fields: {'variant': variant.toJson()},
      files: [skinFile],
    ),
    deserializeSuccess: (response) =>
        MinecraftProfileResponse.fromJson(response.body),
    deserializeClientFailure: (response) =>
        MinecraftErrorResponse.fromJson(response.body),
  );

  Map<String, String> _buildAuthorizationHeader(String accessToken) => {
    'Authorization': 'Bearer $accessToken',
  };
}
