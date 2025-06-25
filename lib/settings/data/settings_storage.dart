import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

import '../../common/logic/app_data_paths.dart';
import '../../common/logic/json.dart';
import 'settings.dart';

// TODO: Refactor this class to be more like FileAccountStorage, to follow the Architecture, should readSettings, not loadSettings, avoid creating it when doesn't exist, maybe SettingRepository?

@immutable
class SettingsStorage {
  const SettingsStorage({required this.file});

  factory SettingsStorage.fromAppDataPaths(AppDataPaths appDataPaths) =>
      SettingsStorage(file: appDataPaths.settings);

  final File file;

  Settings loadSettings() {
    Settings saveDefault() {
      const defaultSettings = Settings();
      saveSettings(defaultSettings);
      return defaultSettings;
    }

    if (!file.existsSync()) {
      return saveDefault();
    }

    final fileContent = file.readAsStringSync().trim();
    if (fileContent.isEmpty) {
      return saveDefault();
    }
    return Settings.fromJson(jsonDecode(file.readAsStringSync()) as JsonMap);
  }

  // TODO: Avoid writeAsStringSync, read: https://dart.dev/tools/linter-rules/avoid_slow_async_io, review all usages of file sync operations
  void saveSettings(Settings settings) {
    file.writeAsStringSync(jsonEncodePretty(settings.toJson()));
  }
}
