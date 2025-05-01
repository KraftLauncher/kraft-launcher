import 'package:flutter/material.dart';
import 'package:kraft_launcher/common/logic/app_data_paths.dart';
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

  test('creates and returns default settings if no file exists', () {
    expect(appDataPaths.settings.existsSync(), false);
    final loadedSettings = settingsStorage.loadSettings();

    expect(loadedSettings, const Settings());
    expect(appDataPaths.settings.existsSync(), true);
  });

  test('loadSettings returns previously saved settings if file exists', () {
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
