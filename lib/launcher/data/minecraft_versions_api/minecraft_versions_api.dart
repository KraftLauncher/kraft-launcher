import 'package:dio/dio.dart';
import 'package:kraft_launcher/common/constants/constants.dart';
import 'package:kraft_launcher/common/logic/dio_helpers.dart';
import 'package:kraft_launcher/common/logic/json.dart';
import 'package:kraft_launcher/common/models/result.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/minecraft_versions_api_failures.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/models/asset_index/api_minecraft_asset_index.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/models/version_details/api_minecraft_version_details.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/models/version_manifest/api_minecraft_version_manifest.dart';
import 'package:meta/meta.dart';

const _host = ApiHosts.pistonMetaMojang;

/// A client for the `piston-meta.mojang.com` API (formerly `launchermeta.mojang.com`).
///
/// Responsibilities:
///
/// * Fetch the Minecraft version manifest, which contains summary version entries and
///   version IDs of the latest versions. Each entry includes a URL
///   for retrieving full version details.
/// * Fetch full version details using the URL from the version manifest.
///   This includes everything needed to install and launch the game,
///   excluding the Java runtime. It also includes a URL for the version’s
///   asset index file to download game assets.
/// * Fetch the asset index file for a specific version using the URL
///   from the version details. Required to download the game assets.
///
/// See also:
///
/// * https://minecraft.wiki/w/Version_manifest.json
/// * https://minecraft.wiki/w/Client.json (version details)
/// * https://piston-meta.mojang.com/mc/game/version_manifest_v2.json
class MinecraftVersionsApi {
  MinecraftVersionsApi({required this.dio});

  @visibleForTesting
  final Dio dio;

  Future<Result<T, MinecraftVersionsApiFailure>> _handleCommonFailures<T>(
    Future<T> Function() run,
  ) async => handleCommonDioFailures(
    () async {
      return Result.success(await run());
    },
    onDeserializationFailure:
        (message) => Result.failure(DeserializationFailure(message)),
    onConnectionFailure:
        (message) => Result.failure(ConnectionFailure(message)),
    onTooManyRequestsFailure:
        () => Result.failure(const TooManyRequestsFailure()),
    onUnknownFailure: (e) => Result.failure(UnknownFailure(e.userErrorMessage)),
  );

  Future<Result<ManifestWithJsonMap, MinecraftVersionsApiFailure>>
  fetchVersionManifest() async => _handleCommonFailures(() async {
    final response = await dio.getUri<JsonMap>(
      Uri.https(_host, 'mc/game/version_manifest_v2.json'),
    );
    final responseData = response.dataOrThrow;

    return (ApiMinecraftVersionManifest.fromJson(responseData), responseData);
  });

  Future<Result<VersionDetailsWithJsonMap, MinecraftVersionsApiFailure>>
  fetchVersionDetails(String versionDetailsUrl) async => _handleCommonFailures(
    () async {
      final response = await dio.getUri<JsonMap>(Uri.parse(versionDetailsUrl));
      final responseData = response.dataOrThrow;
      return (ApiMinecraftVersionDetails.fromJson(responseData), responseData);
    },
  );

  Future<Result<ApiMinecraftAssetIndex, MinecraftVersionsApiFailure>>
  fetchAssetIndex(String assetIndexUrl) async =>
      _handleCommonFailures(() async {
        final response = await dio.getUri<JsonMap>(Uri.parse(assetIndexUrl));
        return ApiMinecraftAssetIndex.fromJson(response.dataOrThrow);
      });
}

// The [JsonMap] is the response without parsing, useful for callers
// to cache the response without using toJson().
// Using toJson() is more verbose and will not include new fields added by the API.
typedef ManifestWithJsonMap =
    (ApiMinecraftVersionManifest manifest, JsonMap jsonMap);
typedef VersionDetailsWithJsonMap =
    (ApiMinecraftVersionDetails versionDetails, JsonMap jsonMap);
