import 'package:api_client/api_client.dart';
import 'package:minecraft_services_client/src/minecraft_services_api_client.dart';
import 'package:minecraft_services_client/src/models/models.dart';

final class HttpMinecraftServicesApiClient
    implements MinecraftServicesApiClient {
  HttpMinecraftServicesApiClient({
    required ApiClient apiClient,
    String host = MinecraftServicesApiClient.apiHost,
  }) : _apiClient = apiClient,
       _host = host;

  final ApiClient _apiClient;
  final String _host;

  Uri _buildUri(String path) => Uri.https(_host, path);

  @override
  Future<MinecraftApiResult<MinecraftLoginResponse>> loginWithXbox({
    required String xstsAccessToken,
    required String xstsUserHash,
  }) => _apiClient.requestJson(
    _buildUri('authentication/login_with_xbox'),
    method: HttpMethod.post,
    body: RequestBody.json({
      'identityToken': 'XBL3.0 x=$xstsUserHash;$xstsAccessToken',
    }),
    deserializeSuccess: (response) =>
        MinecraftLoginResponse.fromJson(response.body),
    deserializeFailure: (response) =>
        MinecraftErrorResponse.fromJson(response.body),
  );

  @override
  Future<MinecraftApiResult<MinecraftEntitlementsResponse>> fetchEntitlements({
    required String accessToken,
  }) => _apiClient.requestJson(
    _buildUri('entitlements/mcstore'),
    method: HttpMethod.get,
    headers: _buildAuthorizationHeader(accessToken),
    deserializeSuccess: (response) =>
        MinecraftEntitlementsResponse.fromJson(response.body),
    deserializeFailure: (response) =>
        MinecraftErrorResponse.fromJson(response.body),
  );

  @override
  Future<MinecraftApiResult<MinecraftProfileResponse>> fetchProfile({
    required String accessToken,
  }) => _apiClient.requestJson(
    _buildUri('minecraft/profile'),
    method: HttpMethod.get,
    headers: _buildAuthorizationHeader(accessToken),
    deserializeSuccess: (response) =>
        MinecraftProfileResponse.fromJson(response.body),
    deserializeFailure: (response) =>
        MinecraftErrorResponse.fromJson(response.body),
  );

  @override
  Future<MinecraftApiResult<MinecraftProfileResponse>> uploadSkin({
    required String accessToken,
    required MultipartFile skinFile,
    required MinecraftSkinVariant variant,
  }) => _apiClient.requestJson(
    _buildUri('minecraft/profile/skins'),
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
