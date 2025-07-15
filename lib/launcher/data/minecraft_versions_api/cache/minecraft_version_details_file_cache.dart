import 'dart:io';

import 'package:kraft_launcher/common/data/json.dart';
import 'package:kraft_launcher/common/data/json_file_cache.dart';
import 'package:kraft_launcher/common/logic/app_data_paths.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/models/version_details/api_minecraft_version_details.dart';

typedef GetFileForVersionId = File Function(String versionId);

class MinecraftVersionDetailsFileCache {
  MinecraftVersionDetailsFileCache({
    required GetFileForVersionId getFileForVersionId,
  }) : _getFileForVersionId = getFileForVersionId,
       _cache = JsonFileCache<ApiMinecraftVersionDetails>(
         fromJson: ApiMinecraftVersionDetails.fromJson,
       );

  factory MinecraftVersionDetailsFileCache.fromAppDataPaths(
    AppDataPaths appDataPaths,
  ) => MinecraftVersionDetailsFileCache(
    getFileForVersionId:
        (versionId) => appDataPaths.versionDetailsFile(versionId),
  );

  final GetFileForVersionId _getFileForVersionId;

  final JsonFileCache<ApiMinecraftVersionDetails> _cache;

  Future<ApiMinecraftVersionDetails?> readCache(String versionId) =>
      _cache.readFromFile(_getFileForVersionId(versionId));

  Future<void> cache(String versionId, JsonMap json) =>
      _cache.writeToFile(_getFileForVersionId(versionId), json);
}
