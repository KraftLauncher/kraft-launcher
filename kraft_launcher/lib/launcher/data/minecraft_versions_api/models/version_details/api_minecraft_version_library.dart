import 'package:equatable/equatable.dart';
import 'package:kraft_launcher/common/data/json.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/models/api_minecraft_rule.dart';
import 'package:meta/meta.dart';

@immutable
class ApiMinecraftVersionLibrary extends Equatable {
  const ApiMinecraftVersionLibrary({
    required this.downloads,
    required this.name,
    required this.rules,
    required this.natives,
    required this.extract,
  });

  factory ApiMinecraftVersionLibrary.fromJson(JsonMap json) =>
      ApiMinecraftVersionLibrary(
        downloads: ApiMinecraftLibraryDownloads.fromJson(
          json['downloads']! as JsonMap,
        ),
        name: json['name']! as String,
        rules: (json['rules'] as JsonList?)
            ?.cast<JsonMap>()
            .map((ruleMap) => ApiMinecraftRule.fromJson(ruleMap))
            .toList(),
        natives: (json['natives'] as Map<String, dynamic>?)
            ?.cast<String, Object>()
            .map((k, v) => MapEntry(k, v as String)),
        extract: () {
          final extractMap = json['extract'] as JsonMap?;
          if (extractMap == null) {
            return null;
          }
          return ApiMinecraftNativesExtractionRules.fromJson(extractMap);
        }(),
      );

  final ApiMinecraftLibraryDownloads downloads;
  final String name;

  final List<ApiMinecraftRule>? rules;

  // Example:
  //
  //  "natives": {
  //    "linux": "natives-linux",
  //    "osx": "natives-osx",
  //    "windows": "natives-windows-${arch}"
  //  }
  //
  // The last version where this is not null is `22w19a`.
  // Likely no longer necessary to handle in newer versions.
  final Map<String, String>? natives;

  // Rules to follow when extracting natives from a library.
  //
  // The last version where this is not null is `22w17a`.
  // Likely no longer necessary to handle in newer versions.
  final ApiMinecraftNativesExtractionRules? extract;

  @override
  List<Object?> get props => [downloads, name, rules, natives, extract];
}

@immutable
class ApiMinecraftLibraryDownloads extends Equatable {
  const ApiMinecraftLibraryDownloads({
    required this.artifact,
    required this.classifiers,
  });

  factory ApiMinecraftLibraryDownloads.fromJson(JsonMap json) =>
      ApiMinecraftLibraryDownloads(
        artifact: () {
          final artifactMap = json['artifact'] as JsonMap?;
          if (artifactMap == null) {
            return null;
          }
          return ApiMinecraftLibraryArtifact.fromJson(artifactMap);
        }(),
        classifiers: (json['classifiers'] as Map<String, dynamic>?)
            ?.cast<String, JsonMap>()
            .map(
              (k, v) => MapEntry(k, ApiMinecraftLibraryArtifact.fromJson(v)),
            ),
      );

  final ApiMinecraftLibraryArtifact? artifact;

  // The last version where this is not null is `22w19a`.
  // Likely no longer necessary to handle in newer versions.
  final Map<String, ApiMinecraftLibraryArtifact>? classifiers;

  @override
  List<Object?> get props => [artifact, classifiers];
}

@immutable
class ApiMinecraftLibraryArtifact extends Equatable {
  const ApiMinecraftLibraryArtifact({
    required this.path,
    required this.sha1,
    required this.size,
    required this.url,
  });

  factory ApiMinecraftLibraryArtifact.fromJson(JsonMap json) =>
      ApiMinecraftLibraryArtifact(
        path: json['path']! as String,
        sha1: json['sha1']! as String,
        size: json['size']! as int,
        url: json['url']! as String,
      );

  final String path;
  final String sha1;
  final int size;
  final String url;

  @override
  List<Object?> get props => [path, sha1, size, url];
}

@immutable
class ApiMinecraftNativesExtractionRules extends Equatable {
  const ApiMinecraftNativesExtractionRules({required this.exclude});

  factory ApiMinecraftNativesExtractionRules.fromJson(JsonMap json) =>
      ApiMinecraftNativesExtractionRules(
        exclude: (json['exclude']! as JsonList).cast<String>(),
      );

  final List<String> exclude;

  @override
  List<Object?> get props => [exclude];
}
