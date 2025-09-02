import 'package:api_client/api_client.dart' show JsonApiResult, MultipartFile;
import 'package:minecraft_services_client/src/models/models.dart';

export 'package:api_client/consumer_types.dart';

/// A low-level client for the `api.minecraftservices.com` API.
///
/// This client provides a thin wrapper over the REST endpoints and does not
/// handle session persistence, caching, or app-specific logic.
/// For higher-level operations, use a repository that depends on this client.
///
/// See also:
///  * https://minecraft.wiki/w/Mojang_API
///  * https://minecraft.wiki/w/Microsoft_authentication
abstract interface class MinecraftServicesApiClient {
  static const apiHost = 'api.minecraftservices.com';

  /// Logs in a user using an XSTS token and a user hash.
  ///
  /// Does not persist session or produce side effects.
  /// Only sends the request and returns the response.
  /// Named [loginWithXbox] to match the API endpoint
  /// `authentication/login_with_xbox`.
  Future<MinecraftApiResult<MinecraftLoginResponse>> loginWithXbox({
    required String xstsAccessToken,
    required String xstsUserHash,
  });

  /// Fetches the Minecraft profile for the authenticated user.
  Future<MinecraftApiResult<MinecraftProfileResponse>> fetchProfile({
    required String accessToken,
  });

  /// Retrieves the entitlements (owned products) of the authenticated user.
  Future<MinecraftApiResult<MinecraftEntitlementsResponse>> fetchEntitlements({
    required String accessToken,
  });

  /// Uploads a new skin for the authenticated user.
  ///
  /// The [skinFile] should ideally have content-type `image/png`, since
  /// Minecraft skins must be PNG files.
  Future<MinecraftApiResult<MinecraftProfileResponse>> uploadSkin({
    required String accessToken,
    required MultipartFile skinFile,
    required MinecraftSkinVariant variant,
  });
}

typedef MinecraftApiResult<T> = JsonApiResult<T, MinecraftErrorResponse>;
