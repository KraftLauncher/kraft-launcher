import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

class AppDataPaths {
  const AppDataPaths({required this.workingDirectory});

  @visibleForTesting
  final Directory workingDirectory;

  File get accounts => File(p.join(workingDirectory.path, 'accounts.json'));

  File get settings => File(p.join(workingDirectory.path, 'settings.json'));

  Directory get versions =>
      Directory(p.join(workingDirectory.path, 'versions'));

  File get versionManifestV2 =>
      File(p.join(versions.path, 'version_manifest_v2.json'));

  Directory _versionDirectory(String versionId) =>
      Directory(p.join(versions.path, versionId));

  File versionDetailsFile(String versionId) =>
      File(p.join(_versionDirectory(versionId).path, '$versionId.json'));

  File versionClientJarFile(String versionId) =>
      File(p.join(_versionDirectory(versionId).path, '$versionId.jar'));

  File get jreManifest => File(p.join(versions.path, 'jre_manifest.json'));

  Directory get runtimes =>
      Directory(p.join(workingDirectory.path, 'runtimes'));

  Directory runtimeComponentDirectory(String runtimeComponentName) =>
      Directory(p.join(runtimes.path, runtimeComponentName));

  /// The directory containing only the game-specific files required to launch Minecraft.
  ///
  /// This excludes any files specific to Kraft Launcher, official Minecraft Launcher,
  /// Java runtimes, and user-specific data such as `worlds` or configuration files (e.g., `options.txt`).
  ///
  /// Notably, the `versions` directory is excluded, as it is specific to the Minecraft Launcher.
  /// The game only requires the absolute path to a client JAR on the classpath to start the game process.
  ///
  /// The following subdirectories are expected within this directory for a successful launch:
  ///
  /// * `assets`
  /// * `libraries`
  /// * `natives`
  Directory get game => Directory(p.join(workingDirectory.path, 'game'));
}
