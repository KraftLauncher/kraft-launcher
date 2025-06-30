import 'package:equatable/equatable.dart';
import 'package:kraft_launcher/common/logic/json.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/minecraft_version_type.dart';
import 'package:meta/meta.dart';

// See: https://minecraft.wiki/w/Version_manifest.json
@immutable
class MinecraftVersionManifest extends Equatable {
  const MinecraftVersionManifest({
    required this.latest,
    required this.versions,
  });

  factory MinecraftVersionManifest.fromJson(JsonMap json) =>
      MinecraftVersionManifest(
        latest: MinecraftLatestVersions.fromJson(json['latest']! as JsonMap),
        versions:
            (json['versions']! as JsonList)
                .cast<JsonMap>()
                .map(
                  (versionMap) => MinecraftManifestVersion.fromJson(versionMap),
                )
                .toList(),
      );

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

  factory MinecraftLatestVersions.fromJson(JsonMap json) =>
      MinecraftLatestVersions(
        release: json['release']! as String,
        snapshot: json['snapshot']! as String,
      );
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
    required this.url,
    required this.time,
    required this.releaseTime,
    required this.sha1,
    required this.complianceLevel,
  });

  factory MinecraftManifestVersion.fromJson(JsonMap json) =>
      MinecraftManifestVersion(
        id: json['id']! as String,
        type: MinecraftVersionType.fromJson(json['type']! as String),
        url: json['url']! as String,
        time: DateTime.parse(json['time']! as String),
        releaseTime: DateTime.parse(json['releaseTime']! as String),
        sha1: json['sha1']! as String,
        complianceLevel: json['complianceLevel']! as int,
      );

  final String id;
  final MinecraftVersionType type;
  final String url;
  final DateTime time;
  final DateTime releaseTime;
  final String sha1;
  final int complianceLevel;

  // 0 until 1.16.4-pre2, and 1 for all versions after.
  // See also: https://minecraft.wiki/w/Client.json
  bool get supportsSafetyFeatures => complianceLevel == 1;

  @override
  List<Object?> get props => [
    id,
    type,
    url,
    time,
    releaseTime,
    sha1,
    complianceLevel,
  ];
}
