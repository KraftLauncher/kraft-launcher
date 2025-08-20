import 'package:api_client/api_client.dart';
import 'package:minecraft_services_client/src/minecraft_services_api_client.dart';
import 'package:minecraft_services_client/src/models/minecraft_entitlements_response.dart';
import 'package:minecraft_services_client/src/models/minecraft_error_response.dart';
import 'package:minecraft_services_client/src/models/minecraft_login_response.dart';
import 'package:minecraft_services_client/src/models/profile/minecraft_profile_response.dart';
import 'package:minecraft_services_client/src/models/profile/skin/enums/minecraft_skin_variant.dart';

final class HttpMinecraftServicesApiClient
    implements MinecraftServicesApiClient {
  HttpMinecraftServicesApiClient({required ApiClient apiClient, String? host})
    : _apiClient = apiClient,
      _host = host ?? MinecraftServicesApiClient.baseUrlHost;

  final ApiClient _apiClient;
  final String _host;

  @override
  MinecraftApiResultFuture<MinecraftLoginResponse> authenticateWithXbox({
    required String xstsToken,
    required String xstsUserHash,
  }) => _apiClient.requestJson(
    Uri.https(_host, 'authentication/login_with_xbox'),
    method: HttpMethod.post,
    body: RequestBody.json({
      'identityToken': 'XBL3.0 x=$xstsUserHash;$xstsToken',
    }),
    deserializeSuccess: (response) =>
        MinecraftLoginResponse.fromJson(response.body),
    deserializeFailure: (response) =>
        MinecraftErrorResponse.fromJson(response.body),
  );

  @override
  MinecraftApiResultFuture<MinecraftEntitlementsResponse> fetchEntitlements({
    required String accessToken,
  }) => _apiClient.requestJson(
    Uri.https(_host, 'entitlements/mcstore'),
    method: HttpMethod.get,
    headers: _buildAuthorizationHeader(accessToken),
    deserializeSuccess: (response) =>
        MinecraftEntitlementsResponse.fromJson(response.body),
    deserializeFailure: (response) =>
        MinecraftErrorResponse.fromJson(response.body),
  );

  @override
  MinecraftApiResultFuture<MinecraftProfileResponse> fetchProfile({
    required String accessToken,
  }) => _apiClient.requestJson(
    Uri.https(_host, 'minecraft/profile'),
    method: HttpMethod.get,
    headers: _buildAuthorizationHeader(accessToken),
    deserializeSuccess: (response) =>
        MinecraftProfileResponse.fromJson(response.body),
    deserializeFailure: (response) =>
        MinecraftErrorResponse.fromJson(response.body),
  );

  @override
  MinecraftApiResultFuture<MinecraftProfileResponse> uploadSkin({
    required String accessToken,
    required MultipartFile skinFile,
    required MinecraftSkinVariant variant,
  }) => _apiClient.requestJson(
    Uri.https(_host, 'minecraft/profile/skins'),
    method: HttpMethod.post,
    headers: _buildAuthorizationHeader(accessToken),
    body: RequestBody.multipart(
      MultipartBody(fields: {'variant': variant.toJson()}, files: [skinFile]),
    ),
    deserializeSuccess: (response) =>
        MinecraftProfileResponse.fromJson(response.body),
    deserializeFailure: (response) =>
        MinecraftErrorResponse.fromJson(response.body),
  );

  Map<String, String> _buildAuthorizationHeader(String accessToken) => {
    'Authorization': 'Bearer $accessToken',
  };
}
