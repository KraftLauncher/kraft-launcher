import 'package:kraft_launcher/settings/data/file_settings_storage.dart';
import 'package:kraft_launcher/settings/data/mappers/file_settings_mapper.dart';
import 'package:kraft_launcher/settings/data/mappers/settings_mapper.dart';
import 'package:kraft_launcher/settings/logic/settings.dart';
import 'package:meta/meta.dart';

/// A repository that provides the app settings.
///
/// Provides a single source of truth for the settings data, ensuring a consistent state across the app.
///
/// **Note:** [loadSettings] must be called before invoking any other operations to avoid a [StateError]:
///
/// ```dart
/// final repository = SettingsRepository(...);
/// await repository.loadSettings();
///
/// await repository.saveSettings(...);
/// ```
class SettingsRepository {
  SettingsRepository({required this.fileSettingsStorage});

  @visibleForTesting
  final FileSettingsStorage fileSettingsStorage;

  Settings? _settings;

  Future<Settings> loadSettings() async {
    final settings =
        (await fileSettingsStorage.readSettings())?.toAppModel() ??
        Settings.defaultSettings();
    _settings = settings;
    return settings;
  }

  Future<Settings> saveSettings({required GeneralSettings? general}) async {
    final initialSettings = _settings;
    if (initialSettings == null) {
      throw StateError(
        'Settings not loaded. Make sure to call `loadSettings()` before saving.',
      );
    }
    final updatedSettings = initialSettings.copyWith(general: general);
    _settings = updatedSettings;
    await fileSettingsStorage.saveSettings(updatedSettings.toFileModel());
    return updatedSettings;
  }
}
