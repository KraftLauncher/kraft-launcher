import 'package:equatable/equatable.dart';
import 'package:kraft_launcher/launcher/logic/minecraft_versions/models/minecraft_rule.dart';
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

  final List<String> exclude;

  @override
  List<Object?> get props => [exclude];
}
