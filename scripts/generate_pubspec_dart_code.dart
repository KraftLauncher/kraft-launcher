// ignore_for_file: avoid_print, depend_on_referenced_packages

import 'dart:io' show File, Process, exit;

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

const _appPackagePath = './kraft_launcher';

void main(List<String> args) async {
  final pubspecYamlFile = File('$_appPackagePath/pubspec.yaml');
  final pubspecYamlText = await pubspecYamlFile.readAsString();
  final pubspecYaml = loadYaml(pubspecYamlText) as YamlMap;

  final fullVersion = pubspecYaml['version'].toString();
  if (!fullVersion.contains('+')) {
    print(
      'The version should contains the build number too (e.g., 1.0.0+1): $fullVersion',
    );
    exit(1);
  }

  final parts = fullVersion.split('+');
  final version = parts[0];
  final versionBuildNumber = parts[1];
  final topics = (pubspecYaml['topics'] as YamlList?)?.map((e) => "'$e'");

  final pubspecDartClassFileDestination =
      (pubspecYaml['pubspec_extract'] as YamlMap)['destination'] as String?;

  if (pubspecDartClassFileDestination == null) {
    print(
      'The class file destination is not set in pubspec.yaml. Add pubspec_extract.destination to ${path.basename(pubspecYamlFile.path)}',
    );
    exit(1);
  }

  final generatedDartFile =
      '''
// dart format off
// coverage:ignore-file

// GENERATED FILE - Don't modify by hand.
// Update pubspec.yaml and run the following script:
// dart ./scripts/generate_pubspec_dart_code.dart

abstract final class Pubspec {

  static const name = '${pubspecYaml['name']}';
  static const fullVersion = '$fullVersion';
  static const version = '$version';
  static const versionBuildNumber = $versionBuildNumber;
  static const description = '${pubspecYaml['description'] ?? ''}';
  static const repository = '${pubspecYaml['repository'] ?? ''}';
  static const homepage = '${pubspecYaml['homepage'] ?? ''}';
  static const issueTracker = '${pubspecYaml['issue_tracker'] ?? ''}';
  static const documentation = '${pubspecYaml['documentation'] ?? ''}';
  static const topics = [${topics?.join(', ') ?? ''}];
}
''';

  final pubspecFileDestination = File(
    '$_appPackagePath/$pubspecDartClassFileDestination',
  );
  if (!pubspecFileDestination.existsSync()) {
    print(
      "The file ${pubspecFileDestination.path} doesn't exist. Please create it first."
      '\n\nCommand:\n'
      'touch ${pubspecFileDestination.path}',
    );
    exit(1);
  }
  await pubspecFileDestination.writeAsString(generatedDartFile);
  await Process.run('dart', ['format', pubspecFileDestination.path]);

  print(pubspecFileDestination.path);
}
