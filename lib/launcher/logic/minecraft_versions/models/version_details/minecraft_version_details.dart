import 'package:equatable/equatable.dart';
import 'package:kraft_launcher/launcher/logic/minecraft_versions/models/minecraft_version_type.dart';
import 'package:kraft_launcher/launcher/logic/minecraft_versions/models/version_details/minecraft_java_version_info.dart';
import 'package:kraft_launcher/launcher/logic/minecraft_versions/models/version_details/minecraft_version_args.dart';
import 'package:kraft_launcher/launcher/logic/minecraft_versions/models/version_details/minecraft_version_asset_index_info.dart';
import 'package:kraft_launcher/launcher/logic/minecraft_versions/models/version_details/minecraft_version_downloads.dart';
import 'package:kraft_launcher/launcher/logic/minecraft_versions/models/version_details/minecraft_version_library.dart';
import 'package:kraft_launcher/launcher/logic/minecraft_versions/models/version_details/minecraft_version_logging_config.dart';
import 'package:meta/meta.dart';

// See: https://minecraft.wiki/w/Client.json
@immutable
class MinecraftVersionDetails extends Equatable {
  const MinecraftVersionDetails({
    required this.legacyArguments,
    required this.arguments,
    required this.assetIndex,
    required this.assetsVersion,
    required this.supportsSafetyFeatures,
    required this.downloads,
    required this.id,
    required this.javaVersion,
    required this.libraries,
    required this.logging,
    required this.mainClass,
    required this.releasedAt,
    required this.updatedAt,
    required this.type,
  });

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
  final String assetsVersion;

  // Versions newer than 1.16.4-pre2 support Minecraft safety features.
  final bool supportsSafetyFeatures;

  final MinecraftVersionDownloads downloads;
  final String id;
  final MinecraftJavaVersionInfo javaVersion;
  final List<MinecraftVersionLibrary> libraries;
  final MinecraftLoggingConfig logging;
  final String mainClass;
  final DateTime releasedAt;
  final DateTime updatedAt;
  final MinecraftVersionType type;

  @override
  List<Object?> get props => [
    legacyArguments,
    arguments,
    assetIndex,
    assetsVersion,
    supportsSafetyFeatures,
    downloads,
    id,
    javaVersion,
    libraries,
    logging,
    mainClass,
    releasedAt,
    updatedAt,
    type,
  ];
}
