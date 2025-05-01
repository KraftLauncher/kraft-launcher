import 'dart:io';

import 'package:kraft_launcher/common/logic/app_data_paths.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory workingDirectory;
  late AppDataPaths appDataPaths;

  setUp(() {
    workingDirectory = Directory('/path/to/example');
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

  test('sets the instance correctly', () {
    AppDataPaths.instance = appDataPaths;
    expect(AppDataPaths.instance, appDataPaths);
  });
}
