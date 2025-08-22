// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'package:json_utils/json_utils.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

void main(List<String> args) async {
  // Determine test mode (defaults to run unit tests only)
  final runUnitTests =
      args.contains('--all') || args.contains('--unit') || args.isEmpty;
  final runIntegrationTests =
      args.contains('--all') || args.contains('--integration');

  // Extract additional arguments for unit or integration tests
  final extraTestArgs = _extractExtraArgs(args);

  if (!runUnitTests && !runIntegrationTests) {
    stderr.writeln('Invalid arguments. Use --unit, --integration, or --all');
    exit(1);
  }

  final modeMessage = switch ((runUnitTests, runIntegrationTests)) {
    (true, true) => 'Running unit and integration tests...',
    (false, true) => 'Running integration tests only...',
    (true, false) => 'Running unit tests only...',
    _ => 'No tests selected.',
  };

  stdout.writeln(modeMessage);

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

    final isFlutter = _isFlutterPackage(join(path, 'pubspec.yaml'));
    final executable = isFlutter ? 'flutter' : 'dart';

    // Run unit tests
    if (runUnitTests) {
      final unitDir = Directory(join(path, 'test'));
      if (unitDir.existsSync()) {
        stdout.writeln('\n=== Running unit tests for "$name" ===');
        await _runTests(
          executable,
          ['test', ...?extraTestArgs],
          path,
          packageName: name,
        );
      } else {
        stdout.writeln('Package "$name" has no unit tests.');
      }
    }

    // Run integration tests
    if (runIntegrationTests && isFlutter) {
      final integrationDir = Directory(join(path, 'integration_test'));
      if (integrationDir.existsSync()) {
        stdout.writeln('\n=== Running integration tests for "$name" ===');
        await _runTests(
          executable,
          ['test', 'integration_test', ...?extraTestArgs],
          path,
          packageName: name,
        );
      } else {
        stdout.writeln('Package "$name" has no integration tests.');
      }
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

Future<void> _runTests(
  String executable,
  List<String> arguments,
  String workingDir, {
  required String packageName,
}) async {
  stdout.writeln(
    '$packageName: Running "$executable ${arguments.join(' ')}"...',
  );
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDir,
    mode: ProcessStartMode.inheritStdio, // Live output
    runInShell: true, // IMPORTANT: Required on Windows to access PATH
  );

  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    stderr.writeln('Tests failed in "$workingDir" with exit code $exitCode');
  } else {
    stdout.writeln('Tests passed in "$workingDir"');
  }
  exit(exitCode);
}

List<String>? _extractExtraArgs(List<String> args) {
  final index = args.indexOf('--');
  if (index == -1) {
    return null;
  }
  return args.sublist(index + 1);
}
