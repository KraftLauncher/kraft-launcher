import 'dart:typed_data';

import 'package:minecraft_services_repository/src/failures.dart';
import 'package:minecraft_services_repository/src/models/models.dart';
import 'package:result/result.dart';

/// A repository providing domain-specific access to Minecraft services.
///
/// Supports operations such as checking Minecraft: Java Edition ownership,
/// fetching profiles, managing skins, and authenticating with Xbox,
/// without exposing low-level REST API or HTTP details.
abstract interface class MinecraftServicesRepository {
  /// Authenticates a user using an XSTS token and a user hash.
  ///
  /// Does not persist session or produce side effects.
  Future<MinecraftServicesResult<MinecraftLoginResponse>> authenticateWithXbox({
    required String xstsAccessToken,
    required String xstsUserHash,
  });

  /// Fetches the Minecraft profile for the authenticated user.
  Future<MinecraftServicesResult<MinecraftProfileResponse>> fetchProfile({
    required String accessToken,
  });

  /// Checks if the user owns a valid Minecraft: Java Edition license.
  ///
  /// Validates the presence of both `product_minecraft` and `game_minecraft`
  /// Microsoft store entitlements from the Minecraft Services API.
  Future<MinecraftServicesResult<bool>> hasValidMinecraftJavaLicense({
    required String accessToken,
  });

  static const maxSkinSizeInKb = 25; // 25 KB

  /// Uploads a new skin for the authenticated user.
  ///
  /// The [skinBytes] argument is typically 3–10 KB. Must not exceed [maxSkinSizeInKb] KB,
  /// otherwise an [ArgumentError] is thrown.
  Future<MinecraftServicesResult<MinecraftProfileResponse>> uploadSkin({
    required String accessToken,
    required Uint8List skinBytes,
    required MinecraftSkinVariant variant,
  });
}

typedef MinecraftServicesResult<T> = Result<T, MinecraftServicesFailure>;
