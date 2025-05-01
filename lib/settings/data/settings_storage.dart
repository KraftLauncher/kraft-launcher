import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

import '../../common/logic/app_data_paths.dart';
import '../../common/logic/json.dart';
import 'settings.dart';

@immutable
class SettingsStorage {
  const SettingsStorage({required this.settingsFile});

  factory SettingsStorage.fromAppDataPaths(AppDataPaths appDataPaths) =>
      SettingsStorage(settingsFile: appDataPaths.settings);

  final File settingsFile;

  Settings loadSettings() {
    Settings? settings;
    if (!settingsFile.existsSync()) {
      settings = const Settings();
      saveSettings(settings);
    }
    return settings ??= Settings.fromJson(
      jsonDecode(settingsFile.readAsStringSync()) as JsonObject,
    );
  }

  void saveSettings(Settings settings) {
    settingsFile.writeAsStringSync(jsonEncodePretty(settings.toJson()));
  }
}
