import 'package:equatable/equatable.dart';
import 'package:kraft_launcher/launcher/logic/minecraft_versions/models/minecraft_version_type.dart';
import 'package:meta/meta.dart';

// See: https://minecraft.wiki/w/Version_manifest.json
@immutable
class MinecraftVersionManifest extends Equatable {
  const MinecraftVersionManifest({
    required this.latest,
    required this.versions,
  });

  final MinecraftLatestVersions latest;
  final List<MinecraftManifestVersion> versions;

  @override
  List<Object?> get props => [latest, versions];
}

@immutable
class MinecraftLatestVersions extends Equatable {
  const MinecraftLatestVersions({
    required this.release,
    required this.snapshot,
  });

  final String release;
  final String snapshot;

  @override
  List<Object?> get props => [release, snapshot];
}

@immutable
class MinecraftManifestVersion extends Equatable {
  const MinecraftManifestVersion({
    required this.id,
    required this.type,
    required this.detailsUrl,
    required this.updatedAt,
    required this.releasedAt,
    required this.sha1,
    required this.supportsSafetyFeatures,
  });

  final String id;
  final MinecraftVersionType type;
  final String detailsUrl;
  final DateTime updatedAt;
  final DateTime releasedAt;
  final String sha1;

  // Versions newer than 1.16.4-pre2 support Minecraft safety features.
  final bool supportsSafetyFeatures;

  @override
  List<Object?> get props => [
    id,
    type,
    detailsUrl,
    updatedAt,
    releasedAt,
    sha1,
    supportsSafetyFeatures,
  ];
}
