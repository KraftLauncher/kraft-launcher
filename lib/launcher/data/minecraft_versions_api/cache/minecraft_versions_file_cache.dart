import 'dart:io';

import 'package:kraft_launcher/common/data/json.dart';
import 'package:kraft_launcher/common/data/json_file_cache.dart';
import 'package:kraft_launcher/common/logic/app_data_paths.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/models/version_manifest/api_minecraft_version_manifest.dart';
import 'package:meta/meta.dart';

class MinecraftVersionsFileCache {
  MinecraftVersionsFileCache({required this.cacheFile})
    : _cache = JsonFileCache<ApiMinecraftVersionManifest>(
        fromJson: ApiMinecraftVersionManifest.fromJson,
      );

  factory MinecraftVersionsFileCache.fromAppDataPaths(
    AppDataPaths appDataPaths,
  ) => MinecraftVersionsFileCache(cacheFile: appDataPaths.versionManifestV2);

  @visibleForTesting
  final File cacheFile;

  final JsonFileCache<ApiMinecraftVersionManifest> _cache;

  Future<ApiMinecraftVersionManifest?> readCache() =>
      _cache.readFromFile(cacheFile);

  Future<void> cache(JsonMap map) => _cache.writeToFile(cacheFile, map);
}
