import 'package:file/memory.dart';
import 'package:kraft_launcher/settings/data/file_settings.dart';
import 'package:kraft_launcher/settings/data/file_settings_storage.dart';
import 'package:kraft_launcher/settings/data/mappers/settings_mapper.dart';
import 'package:kraft_launcher/settings/logic/settings.dart';
import 'package:test/test.dart';

void main() {
  late FileSettingsStorage fileSettingsStorage;
  late MemoryFileSystem memoryFileSystem;

  setUp(() {
    memoryFileSystem = MemoryFileSystem.test();
    fileSettingsStorage = FileSettingsStorage(
      file: memoryFileSystem.file('settings.json'),
    );
  });

  Future<FileSettings> readSettingsNotNull() async {
    final settings = await fileSettingsStorage.readSettings();

    if (settings == null) {
      fail(
        'Expected to read non-null settings after saving, but got null. This suggests the save or read operation did not succeed. There might be a bug in this test.',
      );
    }

    return settings;
  }

  final dummySettings = Settings.defaultSettings().toFileModel();

  group('readSettings', () {
    test('returns null if file does not exist', () async {
      final file = fileSettingsStorage.file;
      expect(file.existsSync(), false);

      final settings = await fileSettingsStorage.readSettings();
      expect(settings, null);

      expect(
        file.existsSync(),
        false,
        reason:
            'The file should not be created when calling readSettings if it does not already exist.',
      );
    });

    test('returns null if file exists but is empty', () async {
      final file = fileSettingsStorage.file;
      await file.create();
      expect(file.existsSync(), true);
      expect(await file.readAsString(), '');

      final settings = await fileSettingsStorage.readSettings();
      expect(settings, null);

      expect(
        await file.readAsString(),
        '',
        reason:
            'The file should not be modified when calling readSettings if file is already empty.',
      );
    });

    test('parses saved settings correctly', () async {
      final settingsToSave = dummySettings;
      await fileSettingsStorage.saveSettings(settingsToSave);

      final savedSettings = await readSettingsNotNull();

      expect(savedSettings.toJson(), settingsToSave.toJson());
      expect(savedSettings, settingsToSave);
    });
  });

  test('saveSettings writes settings correctly to disk', () async {
    final settingsToSave = dummySettings;
    await fileSettingsStorage.saveSettings(settingsToSave);

    final savedSettings = await readSettingsNotNull();

    expect(savedSettings.toJson(), settingsToSave.toJson());
    expect(savedSettings, settingsToSave);
  });
}
