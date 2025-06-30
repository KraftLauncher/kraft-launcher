import 'package:equatable/equatable.dart';
import 'package:kraft_launcher/common/logic/json.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/minecraft_rule.dart';
import 'package:meta/meta.dart';

@immutable
class MinecraftVersionLibrary extends Equatable {
  const MinecraftVersionLibrary({
    required this.downloads,
    required this.name,
    required this.rules,
    required this.natives,
    required this.extract,
  });

  factory MinecraftVersionLibrary.fromJson(JsonMap json) =>
      MinecraftVersionLibrary(
        downloads: MinecraftLibraryDownloads.fromJson(
          json['downloads']! as JsonMap,
        ),
        name: json['name']! as String,
        rules:
            (json['rules'] as JsonList?)
                ?.cast<JsonMap>()
                .map((ruleMap) => MinecraftRule.fromJson(ruleMap))
                .toList(),
        natives: (json['natives'] as Map<String, dynamic>?)
            ?.cast<String, Object>()
            .map((k, v) => MapEntry(k, v as String)),
        extract: () {
          final extractMap = json['extract'] as JsonMap?;
          if (extractMap == null) {
            return null;
          }
          return MinecraftNativesExtractionRules.fromJson(extractMap);
        }(),
      );

  final MinecraftLibraryDownloads downloads;
  final String name;

  final List<MinecraftRule>? rules;

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
  final MinecraftNativesExtractionRules? extract;

  @override
  List<Object?> get props => [downloads, name, rules, natives, extract];
}

@immutable
class MinecraftLibraryDownloads extends Equatable {
  const MinecraftLibraryDownloads({
    required this.artifact,
    required this.classifiers,
  });

  factory MinecraftLibraryDownloads.fromJson(JsonMap json) =>
      MinecraftLibraryDownloads(
        artifact: () {
          final artifactMap = json['artifact'] as JsonMap?;
          if (artifactMap == null) {
            return null;
          }
          return MinecraftLibraryArtifact.fromJson(artifactMap);
        }(),
        classifiers: (json['classifiers'] as Map<String, dynamic>?)
            ?.cast<String, JsonMap>()
            .map((k, v) => MapEntry(k, MinecraftLibraryArtifact.fromJson(v))),
      );

  final MinecraftLibraryArtifact? artifact;

  // The last version where this is not null is `22w19a`.
  // Likely no longer necessary to handle in newer versions.
  final Map<String, MinecraftLibraryArtifact>? classifiers;

  @override
  List<Object?> get props => [artifact, classifiers];
}

@immutable
class MinecraftLibraryArtifact extends Equatable {
  const MinecraftLibraryArtifact({
    required this.path,
    required this.sha1,
    required this.size,
    required this.url,
  });

  factory MinecraftLibraryArtifact.fromJson(JsonMap json) =>
      MinecraftLibraryArtifact(
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
class MinecraftNativesExtractionRules extends Equatable {
  const MinecraftNativesExtractionRules({required this.exclude});

  factory MinecraftNativesExtractionRules.fromJson(JsonMap json) =>
      MinecraftNativesExtractionRules(
        exclude: (json['exclude']! as JsonList).cast<String>(),
      );

  final List<String> exclude;

  @override
  List<Object?> get props => [exclude];
}
