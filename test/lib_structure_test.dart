import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

// TODO: KEEP this is a general quality check for the entire codebase and repo in scripts, not a test! Should work for all packages

// A test to ensure all test files have corresponding source files in the lib directory.
// This test will fail if a file is refactored (moved or renamed) in the lib directory
// without making the same change to its matching file in the test directory.
// This helps maintain consistency between source and test file structures.

// Files inside the "test" directory that do not need a matching file in the lib directory.
const _exceptions = [
  'lib_structure_test.dart',
  'verify_dart_app_version.dart',
  'verify_localizations_test.dart',
];

void main() {
  final testDir = Directory('test');
  final libDir = Directory('lib');

  test('all test files have matching lib files', () {
    final testFiles =
        testDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('_test.dart'))
            .toList();

    for (final testFile in testFiles) {
      final relativeTestPath = p.relative(testFile.path, from: 'test');
      final libPath = p.join(
        libDir.path,
        relativeTestPath.replaceAll('_test.dart', '.dart'),
      );

      final libFile = File(libPath);

      if (_exceptions.any(
        (path) => testFile.path.replaceFirst('test/', '') == path,
      )) {
        continue;
      }

      expect(
        libFile.existsSync(),
        true,
        reason:
            'Expected "$libPath" to exist for the test file "${testFile.path}"',
      );
    }
  });
}
