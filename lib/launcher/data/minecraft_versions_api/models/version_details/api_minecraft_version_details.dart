import 'package:equatable/equatable.dart';
import 'package:kraft_launcher/common/logic/json.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/models/api_minecraft_version_type.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/models/version_details/api_minecraft_java_version_info.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/models/version_details/api_minecraft_version_args.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/models/version_details/api_minecraft_version_asset_index_info.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/models/version_details/api_minecraft_version_downloads.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/models/version_details/api_minecraft_version_library.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/models/version_details/api_minecraft_version_logging_config.dart';
import 'package:meta/meta.dart';

// See: https://minecraft.wiki/w/Client.json
@immutable
class ApiMinecraftVersionDetails extends Equatable {
  const ApiMinecraftVersionDetails({
    required this.minecraftArguments,
    required this.arguments,
    required this.assetIndex,
    required this.assets,
    required this.complianceLevel,
    required this.downloads,
    required this.id,
    required this.javaVersion,
    required this.libraries,
    required this.logging,
    required this.mainClass,
    required this.minimumLauncherVersion,
    required this.releaseTime,
    required this.time,
    required this.type,
  });

  factory ApiMinecraftVersionDetails.fromJson(
    JsonMap json,
  ) => ApiMinecraftVersionDetails(
    // It might be confusing, but [minecraftArguments] has been replaced with arguments
    // in newer Minecraft versions, so [arguments] is used (JVM + game) arguments
    // where minecraftArguments is only the game args.
    minecraftArguments: json['minecraftArguments'] as String?,
    arguments: () {
      final argumentsMap = json['arguments'] as JsonMap?;
      if (argumentsMap == null) {
        return null;
      }
      return ApiMinecraftVersionArgs.fromJson(argumentsMap);
    }(),
    assetIndex: ApiMinecraftVersionAssetIndexInfo.fromJson(
      json['assetIndex']! as JsonMap,
    ),
    assets: json['assets']! as String,
    complianceLevel: json['complianceLevel']! as int,
    downloads: ApiMinecraftVersionDownloads.fromJson(
      json['downloads']! as JsonMap,
    ),
    id: json['id']! as String,
    javaVersion: ApiMinecraftJavaVersionInfo.fromJson(
      json['javaVersion']! as JsonMap,
    ),
    libraries:
        (json['libraries']! as JsonList)
            .cast<JsonMap>()
            .map(
              (libraryMap) => ApiMinecraftVersionLibrary.fromJson(libraryMap),
            )
            .toList(),
    logging: ApiMinecraftLoggingConfig.fromJson(json['logging']! as JsonMap),
    mainClass: json['mainClass']! as String,
    minimumLauncherVersion: json['minimumLauncherVersion']! as int,
    releaseTime: DateTime.parse(json['releaseTime']! as String),
    time: DateTime.parse(json['time']! as String),
    type: ApiMinecraftVersionType.fromJson(json['type']! as String),
  );

  /// The old Minecraft arguments used in versions before 1.13.
  /// Replaced by [arguments] in newer versions.
  ///
  /// Unlike [arguments], this only contains the game arguments without
  /// the JVM arguments.
  ///
  /// Example:
  ///
  /// "--username ${auth_player_name} --version ${version_name} --gameDir ${game_directory} --assetsDir ${assets_root} --assetIndex ${assets_index_name} --uuid ${auth_uuid} --accessToken ${auth_access_token} --userProperties ${user_properties} --userType ${user_type}"
  final String? minecraftArguments;

  /// The Minecraft arguments used in version 1.13 or later.
  /// This is `null` for older versions, where [minecraftArguments] should be used instead.
  final ApiMinecraftVersionArgs? arguments;

  final ApiMinecraftVersionAssetIndexInfo assetIndex;

  /// The assets version (e.g., `26` for 1.21.7).
  final String assets;

  /// 0 until 1.16.4-pre2, and 1 for all versions after.
  /// A value of 0 causes the official launcher to warn the player about missing
  /// player safety features when this version is selected.
  /// See also: https://minecraft.wiki/w/Client.json
  final int complianceLevel;

  final ApiMinecraftVersionDownloads downloads;
  final String id;
  final ApiMinecraftJavaVersionInfo javaVersion;
  final List<ApiMinecraftVersionLibrary> libraries;
  final ApiMinecraftLoggingConfig logging;
  final String mainClass;
  final int minimumLauncherVersion;
  final DateTime releaseTime;
  final DateTime time;
  final ApiMinecraftVersionType type;

  @override
  List<Object?> get props => [
    minecraftArguments,
    arguments,
    assetIndex,
    assets,
    complianceLevel,
    downloads,
    id,
    javaVersion,
    libraries,
    logging,
    mainClass,
    minimumLauncherVersion,
    releaseTime,
    time,
    type,
  ];
}
