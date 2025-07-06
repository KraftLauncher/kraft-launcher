import 'dart:io';

import 'package:kraft_launcher/common/logic/app_data_paths.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory workingDirectory;
  late AppDataPaths appDataPaths;

  setUp(() {
    workingDirectory = Directory('/path/to/any');
    appDataPaths = AppDataPaths(workingDirectory: workingDirectory);
  });

  test('returns the correct working directory', () {
    expect(appDataPaths.workingDirectory, workingDirectory);
  });

  test('returns the correct path for the accounts file', () {
    expect(
      appDataPaths.accounts.path,
      p.join(workingDirectory.path, 'accounts.json'),
    );
  });

  test('returns the correct path for the settings file', () {
    expect(
      appDataPaths.settings.path,
      p.join(workingDirectory.path, 'settings.json'),
    );
  });

  test('returns the correct path for versions directory', () {
    expect(
      appDataPaths.versions.path,
      p.join(workingDirectory.path, 'versions'),
    );
  });

  test('returns the correct path for versionManifestV2 file', () {
    expect(
      appDataPaths.versionManifestV2.path,
      p.join(appDataPaths.versions.path, 'version_manifest_v2.json'),
    );
  });

  test('returns correct path for a version details file', () {
    const versionId = '1.20.1';
    expect(
      appDataPaths.versionDetailsFile(versionId).path,
      p.join(appDataPaths.versions.path, versionId, '$versionId.json'),
    );
  });

  test('returns correct path for a version client JAR file', () {
    const versionId = '1.20.1';
    expect(
      appDataPaths.versionClientJarFile(versionId).path,
      p.join(appDataPaths.versions.path, versionId, '$versionId.jar'),
    );
  });

  test('returns the correct path for jreManifest file', () {
    expect(
      appDataPaths.jreManifest.path,
      p.join(appDataPaths.versions.path, 'jre_manifest.json'),
    );
  });

  test('returns the correct path for runtimes directory', () {
    expect(
      appDataPaths.runtimes.path,
      p.join(workingDirectory.path, 'runtimes'),
    );
  });

  test('returns correct path for a runtime component directory', () {
    const runtimeComponentName = 'java-runtime-delta';
    expect(
      appDataPaths.runtimeComponentDirectory(runtimeComponentName).path,
      p.join(appDataPaths.runtimes.path, runtimeComponentName),
    );
  });

  test('returns the correct path for game directory', () {
    expect(
      appDataPaths.game.path,
      p.join(appDataPaths.workingDirectory.path, 'game'),
    );
  });
}
