import 'dart:convert';
import 'dart:io';

import 'package:kraft_launcher/common/data/json.dart';
import 'package:kraft_launcher/common/logic/app_data_paths.dart';
import 'package:kraft_launcher/settings/data/file_settings.dart';

class SettingsFileStorage {
  SettingsFileStorage({required File file}) : _file = file;

  factory SettingsFileStorage.fromAppDataPaths(AppDataPaths appDataPaths) =>
      SettingsFileStorage(file: appDataPaths.settings);

  final File _file;

  Future<FileSettings?> readSettings() async {
    if (!_file.existsSync()) {
      return null;
    }

    final fileContent = (await _file.readAsString()).trim();
    if (fileContent.isEmpty) {
      return null;
    }
    return FileSettings.fromJson(jsonDecode(fileContent) as JsonMap);
  }

  Future<void> saveSettings(FileSettings settings) =>
      _file.writeAsString(jsonEncodePretty(settings.toJson()));
}
