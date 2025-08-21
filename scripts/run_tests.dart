// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'package:json_utils/json_utils.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

void main() async {
  final result = await Process.run('dart', [
    'pub',
    'workspace',
    'list',
    '--json',
  ], runInShell: true);

  if (result.exitCode != 0) {
    stderr.writeln('Failed to list workspace packages:\n${result.stderr}');
    exit(result.exitCode);
  }

  final json = jsonDecode(result.stdout as String) as Map<String, dynamic>;
  final packages = (json['packages'] as List<dynamic>).cast<JsonMap>();

  for (final package in packages) {
    final name = package['name']! as String;
    final path = package['path']! as String;

    final testDir = Directory(join(path, 'test'));
    if (!testDir.existsSync()) {
      stdout.writeln('Package "$name" has no tests. Skipping...');
      continue;
    }

    final isFlutter = _isFlutterPackage(join(path, 'pubspec.yaml'));
    final executable = isFlutter ? 'flutter' : 'dart';

    stdout.writeln('\n=== Running "$executable test" for $name ===');

    final process = await Process.start(
      executable,
      ['test'],
      workingDirectory: path,
      mode: ProcessStartMode.inheritStdio, // live output
    );

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      stderr.writeln('Tests failed for "$name" with exit code $exitCode');
    } else {
      stdout.writeln('Tests passed for "$name"');
    }
  }
}

bool _isFlutterPackage(String pubspecPath) {
  final file = File(pubspecPath);
  if (!file.existsSync()) {
    return false;
  }

  final yaml = loadYaml(file.readAsStringSync());
  if (yaml is! Map) {
    return false;
  }

  final dependencies = yaml['dependencies'];
  return dependencies is Map && dependencies.containsKey('flutter');
}
