import 'package:equatable/equatable.dart';
import 'package:kraft_launcher/common/logic/json.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/models/api_minecraft_version_type.dart';
import 'package:meta/meta.dart';

// See: https://minecraft.wiki/w/Version_manifest.json
@immutable
class ApiMinecraftVersionManifest extends Equatable {
  const ApiMinecraftVersionManifest({
    required this.latest,
    required this.versions,
  });

  factory ApiMinecraftVersionManifest.fromJson(JsonMap json) =>
      ApiMinecraftVersionManifest(
        latest: ApiMinecraftLatestVersions.fromJson(json['latest']! as JsonMap),
        versions:
            (json['versions']! as JsonList)
                .cast<JsonMap>()
                .map(
                  (versionMap) =>
                      ApiMinecraftManifestVersion.fromJson(versionMap),
                )
                .toList(),
      );

  final ApiMinecraftLatestVersions latest;
  final List<ApiMinecraftManifestVersion> versions;

  @override
  List<Object?> get props => [latest, versions];
}

@immutable
class ApiMinecraftLatestVersions extends Equatable {
  const ApiMinecraftLatestVersions({
    required this.release,
    required this.snapshot,
  });

  factory ApiMinecraftLatestVersions.fromJson(JsonMap json) =>
      ApiMinecraftLatestVersions(
        release: json['release']! as String,
        snapshot: json['snapshot']! as String,
      );
  final String release;
  final String snapshot;

  @override
  List<Object?> get props => [release, snapshot];
}

// TODO: Rename to ApiMinecraftVersionInfo? Also rename the app model that's MinecraftManifestVersion.
@immutable
class ApiMinecraftManifestVersion extends Equatable {
  const ApiMinecraftManifestVersion({
    required this.id,
    required this.type,
    required this.url,
    required this.time,
    required this.releaseTime,
    required this.sha1,
    required this.complianceLevel,
  });

  factory ApiMinecraftManifestVersion.fromJson(JsonMap json) =>
      ApiMinecraftManifestVersion(
        id: json['id']! as String,
        type: ApiMinecraftVersionType.fromJson(json['type']! as String),
        url: json['url']! as String,
        time: DateTime.parse(json['time']! as String),
        releaseTime: DateTime.parse(json['releaseTime']! as String),
        sha1: json['sha1']! as String,
        complianceLevel: json['complianceLevel']! as int,
      );

  final String id;
  final ApiMinecraftVersionType type;
  final String url;

  /// A timestamp in ISO 8601 format of when the version files were last updated on the manifest.
  final DateTime time;
  final DateTime releaseTime;
  final String sha1;

  /// 0 until 1.16.4-pre2, and 1 for all versions after.
  /// A value of 0 causes the official launcher to warn the player about missing
  /// player safety features when this version is selected.
  /// See also: https://minecraft.wiki/w/Client.json
  final int complianceLevel;

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
