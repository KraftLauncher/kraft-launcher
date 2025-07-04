import 'dart:io';

import 'package:kraft_launcher/common/data/json_file_cache.dart';
import 'package:kraft_launcher/common/logic/app_data_paths.dart';
import 'package:kraft_launcher/common/logic/json.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/models/version_details/api_minecraft_version_details.dart';
import 'package:meta/meta.dart';

class MinecraftVersionDetailsFileCache {
  MinecraftVersionDetailsFileCache({required this.getFileForVersionId})
    : _cache = JsonFileCache<ApiMinecraftVersionDetails>(
        fromJson: ApiMinecraftVersionDetails.fromJson,
      );

  factory MinecraftVersionDetailsFileCache.fromAppDataPaths(
    AppDataPaths appDataPaths,
  ) => MinecraftVersionDetailsFileCache(
    getFileForVersionId:
        (versionId) => appDataPaths.versionDetailsFile(versionId),
  );

  @visibleForTesting
  final File Function(String versionId) getFileForVersionId;

  final JsonFileCache<ApiMinecraftVersionDetails> _cache;

  Future<ApiMinecraftVersionDetails?> readCache(String versionId) =>
      _cache.readFromFile(getFileForVersionId(versionId));

  Future<void> cache(String versionId, JsonMap json) =>
      _cache.writeToFile(getFileForVersionId(versionId), json);
}
