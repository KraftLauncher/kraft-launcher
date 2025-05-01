// A test to ensure the generated version constant from pubspec.yaml in Dart code is up to date.

import 'dart:io';

import 'package:kraft_launcher/common/generated/pubspec.g.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('dart version constant matches the version in pubspec.yaml', () {
    final pubspecYamlContent = File('pubspec.yaml').readAsStringSync();
    final pubspecYamlVersion =
        (loadYaml(pubspecYamlContent) as YamlMap)['version'] as String;
    expect(Pubspec.fullVersion, pubspecYamlVersion);
  });
}
