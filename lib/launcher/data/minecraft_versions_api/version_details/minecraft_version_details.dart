import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../../../common/logic/json.dart';
import '../minecraft_version_type.dart';
import 'minecraft_java_version_info.dart';
import 'minecraft_version_args.dart';
import 'minecraft_version_asset_index_info.dart';
import 'minecraft_version_downloads.dart';
import 'minecraft_version_library.dart';
import 'minecraft_version_logging_config.dart';

// See: https://minecraft.wiki/w/Client.json
@immutable
class MinecraftVersionDetails extends Equatable {
  const MinecraftVersionDetails({
    required this.legacyArguments,
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

  factory MinecraftVersionDetails.fromJson(
    JsonMap json,
  ) => MinecraftVersionDetails(
    // TODO: If this raw data model was separated from app model, then it should stay close to the source (minecraftArguments rather than legacyArguments)
    //  just document it and make it clear in the one we care about
    legacyArguments: json['minecraftArguments'] as String?,
    arguments: () {
      final argumentsMap = json['arguments'] as JsonMap?;
      if (argumentsMap == null) {
        return null;
      }
      return MinecraftVersionArgs.fromJson(argumentsMap);
    }(),
    assetIndex: MinecraftVersionAssetIndexInfo.fromJson(
      json['assetIndex']! as JsonMap,
    ),
    assets: json['assets']! as String,
    complianceLevel: json['complianceLevel']! as int,
    downloads: MinecraftVersionDownloads.fromJson(
      json['downloads']! as JsonMap,
    ),
    id: json['id']! as String,
    javaVersion: MinecraftJavaVersionInfo.fromJson(
      json['javaVersion']! as JsonMap,
    ),
    libraries:
        (json['libraries']! as List<dynamic>)
            .cast<JsonMap>()
            .map((libraryMap) => MinecraftVersionLibrary.fromJson(libraryMap))
            .toList(),
    logging: MinecraftLoggingConfig.fromJson(json['logging']! as JsonMap),
    mainClass: json['mainClass']! as String,
    minimumLauncherVersion: json['minimumLauncherVersion']! as int,
    releaseTime: DateTime.parse(json['releaseTime']! as String),
    time: DateTime.parse(json['time']! as String),
    type: MinecraftVersionType.fromJson(json['type']! as String),
  );

  /// The old Minecraft arguments used in versions before 1.13.
  /// Replaced by [arguments] in newer versions.
  ///
  /// Example:
  ///
  /// "--username ${auth_player_name} --version ${version_name} --gameDir ${game_directory} --assetsDir ${assets_root} --assetIndex ${assets_index_name} --uuid ${auth_uuid} --accessToken ${auth_access_token} --userProperties ${user_properties} --userType ${user_type}"
  final String? legacyArguments;

  /// The Minecraft arguments used in version 1.13 or later.
  /// This is `null` for older versions, where [legacyArguments] should be used instead.
  final MinecraftVersionArgs? arguments;

  final MinecraftVersionAssetIndexInfo assetIndex;
  final String assets;
  final int complianceLevel;
  final MinecraftVersionDownloads downloads;
  final String id;
  final MinecraftJavaVersionInfo javaVersion;
  final List<MinecraftVersionLibrary> libraries;
  final MinecraftLoggingConfig logging;
  final String mainClass;
  final int minimumLauncherVersion;
  final DateTime releaseTime;
  final DateTime time;
  final MinecraftVersionType type;

  @override
  List<Object?> get props => [
    legacyArguments,
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
