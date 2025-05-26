import 'package:flutter/material.dart';
import 'package:kraft_launcher/common/logic/app_data_paths.dart';
import 'package:kraft_launcher/common/logic/json.dart';
import 'package:kraft_launcher/settings/data/settings.dart';
import 'package:kraft_launcher/settings/data/settings_storage.dart';
import 'package:test/test.dart';

import '../../common/helpers/temp_file_utils.dart';

void main() {
  late SettingsStorage settingsStorage;
  late AppDataPaths appDataPaths;

  setUp(() {
    final tempTestDir = createTempTestDir();
    appDataPaths = AppDataPaths(workingDirectory: tempTestDir);
    settingsStorage = SettingsStorage.fromAppDataPaths(appDataPaths);
  });

  tearDown(() {
    appDataPaths.workingDirectory.deleteSync(recursive: true);
  });

  group('loadSettings', () {
    test('creates and returns default settings if no file exists', () {
      expect(appDataPaths.settings.existsSync(), false);
      final loadedSettings = settingsStorage.loadSettings();

      expect(loadedSettings, const Settings());
      expect(appDataPaths.settings.existsSync(), true);
    });

    test('returns previously saved settings if file exists', () {
      const savedSettings = Settings(
        general: GeneralSettings(
          useDynamicColor: false,
          accentColor: Colors.black,
        ),
      );

      settingsStorage.saveSettings(savedSettings);
      expect(appDataPaths.settings.existsSync(), true);

      final loadedSettings = settingsStorage.loadSettings();
      expect(loadedSettings, savedSettings);
    });

    test('overwrites file if file exists but is empty', () {
      final file = appDataPaths.settings;
      file.createSync();
      expect(file.existsSync(), true);
      expect(file.readAsStringSync(), '');

      final settings = settingsStorage.loadSettings();

      expect(settings.toJson(), const Settings().toJson());
      expect(
        file.readAsStringSync(),
        jsonEncodePretty(const Settings().toJson()),
      );
    });
  });

  test('saveSettings writes settings to file correctly', () {
    expect(appDataPaths.settings.existsSync(), false);
    const settings = Settings(
      general: GeneralSettings(useClassicMaterialDesign: false),
    );
    settingsStorage.saveSettings(settings);
    expect(appDataPaths.settings.existsSync(), true);
    expect(settingsStorage.loadSettings(), settings);
  });
}
