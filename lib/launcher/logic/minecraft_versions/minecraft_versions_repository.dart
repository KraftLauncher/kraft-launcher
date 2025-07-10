import 'dart:async';

import 'package:kraft_launcher/common/models/result.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/cache/minecraft_version_details_file_cache.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/cache/minecraft_versions_file_cache.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/mappers/api_minecraft_asset_index_mapper.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/mappers/api_minecraft_version_details_mapper.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/mappers/api_minecraft_version_manifest_mapper.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/minecraft_versions_api.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/minecraft_versions_api_failures.dart';
import 'package:kraft_launcher/launcher/logic/minecraft_versions/models/asset_index/minecraft_asset_index.dart';
import 'package:kraft_launcher/launcher/logic/minecraft_versions/models/version_details/minecraft_version_details.dart';
import 'package:kraft_launcher/launcher/logic/minecraft_versions/models/version_manifest/minecraft_version_manifest.dart';
import 'package:meta/meta.dart';

/// Provides Minecraft version data for the app,
/// containing the necessary information to download any Minecraft version.
///
/// Responsibilities:
///
/// * Provide the version manifest, which includes a list of available Minecraft versions
///   along with the latest release and snapshot versions. Each version entry contains a URL
///   for retrieving full version details.
/// * Provide full version details for a specific Minecraft version
///   using a URL from the version manifest.
/// * Provide the asset index for a version using a URL from the version details.
/// * Caches data to avoid unnecessary API calls.
///
/// See also: [MinecraftVersionsApi]
class MinecraftVersionsRepository {
  MinecraftVersionsRepository({
    required this.minecraftVersionsApi,
    required this.minecraftVersionsFileCache,
    required this.minecraftVersionDetailsFileCache,
  });

  @visibleForTesting
  final MinecraftVersionsApi minecraftVersionsApi;

  // TODO: Implement cache invalidation based on expiration DateTime.
  //  Currently, cached data is always used if available without checking expiration unless forceRefresh is true.
  @visibleForTesting
  final MinecraftVersionsFileCache minecraftVersionsFileCache;
  @visibleForTesting
  final MinecraftVersionDetailsFileCache minecraftVersionDetailsFileCache;

  Future<Result<MinecraftVersionManifest, MinecraftVersionsApiFailure>>
  fetchVersionManifest({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await minecraftVersionsFileCache.readCache();
      if (cached != null) {
        return Result.success(cached.toAppModel());
      }
    }
    final result = await minecraftVersionsApi.fetchVersionManifest();
    return result.mapSuccess((value) {
      final (parsed, map) = value;
      unawaited(minecraftVersionsFileCache.cache(map));
      return parsed.toAppModel();
    });
  }

  Future<Result<MinecraftVersionDetails, MinecraftVersionsApiFailure>>
  fetchVersionDetails(
    // Example: https://piston-meta.mojang.com/v1/packages/5d22e5893fd9c565b9a3039f1fc842aef2c4aefc/1.21.7.json
    String versionDetailsUrl, {

    // This is used for caching purposes. Although the version ID can be extracted
    // from [versionDetailsUrl], callers typically already have it available, so
    // it is passed directly for convenience and clarity.
    required String versionId,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await minecraftVersionDetailsFileCache.readCache(
        versionId,
      );
      if (cached != null) {
        return Result.success(cached.toAppModel());
      }
    }
    final result = await minecraftVersionsApi.fetchVersionDetails(
      versionDetailsUrl,
    );
    return result.mapSuccess((value) {
      final (parsed, map) = value;
      unawaited(minecraftVersionDetailsFileCache.cache(versionId, map));
      return parsed.toAppModel();
    });
  }

  Future<Result<MinecraftAssetIndex, MinecraftVersionsApiFailure>>
  fetchAssetIndex(String assetIndexUrl) async {
    final result = await minecraftVersionsApi.fetchAssetIndex(assetIndexUrl);
    return result.mapSuccess((value) => value.toAppModel());
  }
}
