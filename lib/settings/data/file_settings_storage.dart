import 'dart:convert';
import 'dart:io';

import 'package:kraft_launcher/common/data/json.dart';
import 'package:kraft_launcher/common/logic/app_data_paths.dart';
import 'package:kraft_launcher/settings/data/file_settings.dart';
import 'package:meta/meta.dart';

@immutable
class FileSettingsStorage {
  const FileSettingsStorage({required this.file});

  factory FileSettingsStorage.fromAppDataPaths(AppDataPaths appDataPaths) =>
      FileSettingsStorage(file: appDataPaths.settings);

  @visibleForTesting
  final File file;

  Future<FileSettings?> readSettings() async {
    if (!file.existsSync()) {
      return null;
    }

    final fileContent = (await file.readAsString()).trim();
    if (fileContent.isEmpty) {
      return null;
    }
    return FileSettings.fromJson(jsonDecode(fileContent) as JsonMap);
  }

  Future<void> saveSettings(FileSettings settings) =>
      file.writeAsString(jsonEncodePretty(settings.toJson()));
}
