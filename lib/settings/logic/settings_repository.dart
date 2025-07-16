import 'package:kraft_launcher/settings/data/settings_file_storage.dart';
import 'package:kraft_launcher/settings/data/mappers/file_settings_mapper.dart';
import 'package:kraft_launcher/settings/data/mappers/settings_mapper.dart';
import 'package:kraft_launcher/settings/logic/settings.dart';

/// Manages in-app settings stored locally on this device.
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
  SettingsRepository({required SettingsFileStorage settingsFileStorage})
    : _settingsFileStorage = settingsFileStorage;

  final SettingsFileStorage _settingsFileStorage;

  Settings? _settings;

  Future<Settings> loadSettings() async {
    final settings =
        (await _settingsFileStorage.readSettings())?.toApp() ??
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
    await _settingsFileStorage.saveSettings(updatedSettings.toFileDto());
    return updatedSettings;
  }
}
