import 'package:api_client/api_client.dart';
import 'package:minecraft_services_client/src/models/minecraft_entitlements_response.dart';
import 'package:minecraft_services_client/src/models/minecraft_error_response.dart';
import 'package:minecraft_services_client/src/models/minecraft_login_response.dart';
import 'package:minecraft_services_client/src/models/profile/minecraft_profile_response.dart';
import 'package:minecraft_services_client/src/models/profile/skin/enums/minecraft_skin_variant.dart';

/// A client for the `api.minecraftservices.com` API.
///
/// See also:
///  * https://minecraft.wiki/w/Mojang_API
///  * https://minecraft.wiki/w/Microsoft_authentication
abstract interface class MinecraftServicesApiClient {
  static const baseUrlHost = 'api.minecraftservices.com';

  /// Authenticates a user using Xbox XSTS token and user hash.
  MinecraftApiResultFuture<MinecraftLoginResponse> authenticateWithXbox({
    required String xstsToken,
    required String xstsUserHash,
  });

  /// Fetches the Minecraft profile data for the authenticated user.
  MinecraftApiResultFuture<MinecraftProfileResponse> fetchProfile({
    required String accessToken,
  });

  /// Retrieves the entitlements (owned products) of the authenticated user.
  MinecraftApiResultFuture<MinecraftEntitlementsResponse> fetchEntitlements({
    required String accessToken,
  });

  /// Uploads a new skin for the authenticated user.
  ///
  /// While not required, it's preferred to hardcode the content-type to `image/png`
  /// when passing a [MultipartFile] to [skinFile] argument
  /// since Minecraft skins are always PNG files.
  MinecraftApiResultFuture<MinecraftProfileResponse> uploadSkin({
    required String accessToken,
    required MultipartFile skinFile,
    required MinecraftSkinVariant variant,
  });
}

typedef MinecraftApiResult<T> = JsonApiResult<T, MinecraftErrorResponse>;
typedef MinecraftApiResultFuture<T> = Future<MinecraftApiResult<T>>;
