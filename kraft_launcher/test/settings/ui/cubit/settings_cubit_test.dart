import 'package:kraft_launcher/settings/logic/settings.dart';
import 'package:kraft_launcher/settings/logic/settings_repository.dart';
import 'package:kraft_launcher/settings/ui/cubit/settings_cubit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late _MockSettingsRepository mockSettingsRepository;
  late SettingsCubit settingsCubit;
  late Settings existingSettings;

  setUp(() {
    mockSettingsRepository = _MockSettingsRepository();
    existingSettings = Settings.defaultSettings();

    when(
      () => mockSettingsRepository.loadSettings(),
    ).thenAnswer((_) async => existingSettings);
    when(
      () => mockSettingsRepository.saveSettings(general: any(named: 'general')),
    ).thenAnswer((_) async => _dummySettings);

    settingsCubit = SettingsCubit(settingsRepository: mockSettingsRepository);

    // loadSettings is called in the constructor, ignore it in all tests.
    verify(() => mockSettingsRepository.loadSettings()).called(1);
  });

  final defaultSettings = Settings.defaultSettings();

  setUpAll(() {
    registerFallbackValue(_dummySettings);
  });

  test('loads the settings initially', () async {
    settingsCubit = SettingsCubit(settingsRepository: mockSettingsRepository);

    // Awaits the loadSettings call that's called in the constructor.
    await Future<void>.delayed(Duration.zero);

    final expectedSettings = existingSettings;

    when(
      () => mockSettingsRepository.loadSettings(),
    ).thenAnswer((_) async => expectedSettings);
    verify(() => mockSettingsRepository.loadSettings()).called(1);

    expect(settingsCubit.state.settings, expectedSettings);
    verifyNoMoreInteractions(mockSettingsRepository);
  });

  test('loadSettings updates the settings correctly', () async {
    existingSettings = defaultSettings.copyWith(
      general: defaultSettings.general.copyWith(
        appLanguage: AppLanguage.de,
        useAccentColor: true,
      ),
    );
    when(
      () => mockSettingsRepository.loadSettings(),
    ).thenAnswer((_) async => existingSettings);

    await settingsCubit.loadSettings();

    verify(() => mockSettingsRepository.loadSettings()).called(1);
    expect(settingsCubit.state.settings, existingSettings);

    verifyNoMoreInteractions(mockSettingsRepository);
  });

  test('loadSettings preserves current UI state', () {
    const currentSelectedCategory = SettingsCategory.java;
    settingsCubit.updateSelectedCategory(currentSelectedCategory);

    expect(settingsCubit.state.selectedCategory, currentSelectedCategory);

    settingsCubit.loadSettings();

    expect(settingsCubit.state.selectedCategory, currentSelectedCategory);
  });

  test('updateSettings updates the settings correctly', () async {
    final initialSettings = defaultSettings;
    final updatedSettings = initialSettings.copyWith(
      general: initialSettings.general.copyWith(
        useClassicMaterialDesign: false,
      ),
    );

    when(
      () => mockSettingsRepository.saveSettings(general: any(named: 'general')),
    ).thenAnswer((_) async => updatedSettings);

    await settingsCubit.updateSettings(general: updatedSettings.general);

    verify(
      () =>
          mockSettingsRepository.saveSettings(general: updatedSettings.general),
    ).called(1);

    verifyNoMoreInteractions(mockSettingsRepository);
  });
}

Settings _dummySettings = Settings.defaultSettings();
