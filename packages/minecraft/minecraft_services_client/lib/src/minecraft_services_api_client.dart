import 'package:api_client/api_client.dart';
import 'package:minecraft_services_client/src/models/models.dart';

export 'package:api_client/api_client.dart' show MediaType, MultipartFile;
export 'package:api_client/api_failures.dart';

/// A client for the `api.minecraftservices.com` API.
///
/// See also:
///  * https://minecraft.wiki/w/Mojang_API
///  * https://minecraft.wiki/w/Microsoft_authentication
abstract interface class MinecraftServicesApiClient {
  static const baseUrlHost = 'api.minecraftservices.com';

  /// Authenticates a user using Xbox XSTS token and user hash.
  Future<MinecraftApiResult<MinecraftLoginResponse>> authenticateWithXbox({
    required String xstsToken,
    required String xstsUserHash,
  });

  /// Fetches the Minecraft profile data for the authenticated user.
  Future<MinecraftApiResult<MinecraftProfileResponse>> fetchProfile({
    required String accessToken,
  });

  /// Retrieves the entitlements (owned products) of the authenticated user.
  Future<MinecraftApiResult<MinecraftEntitlementsResponse>> fetchEntitlements({
    required String accessToken,
  });

  /// Uploads a new skin for the authenticated user.
  ///
  /// While not strictly required, it's recommended to set the content-type
  /// of the [skinFile] to `image/png`, since Minecraft skins must be PNG files.
  Future<MinecraftApiResult<MinecraftProfileResponse>> uploadSkin({
    required String accessToken,
    required MultipartFile skinFile,
    required MinecraftSkinVariant variant,
  });
}

typedef MinecraftApiResult<T> = JsonApiResult<T, MinecraftErrorResponse>;
