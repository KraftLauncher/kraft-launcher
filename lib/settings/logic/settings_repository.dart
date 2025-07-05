import 'package:kraft_launcher/settings/data/file_settings_storage.dart';
import 'package:kraft_launcher/settings/data/mappers/file_settings_mapper.dart';
import 'package:kraft_launcher/settings/data/mappers/settings_mapper.dart';
import 'package:kraft_launcher/settings/logic/settings.dart';
import 'package:meta/meta.dart';

class SettingsRepository {
  SettingsRepository({required this.fileSettingsStorage});

  @visibleForTesting
  final FileSettingsStorage fileSettingsStorage;

  Future<Settings> loadSettings() async {
    final settings = (await fileSettingsStorage.readSettings())?.toAppModel();
    if (settings == null) {
      return Settings.defaultSettings();
    }
    return settings;
  }

  Future<void> saveSettings(Settings settings) =>
      fileSettingsStorage.saveSettings(settings.toFileModel());
}
