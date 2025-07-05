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
      () => mockSettingsRepository.saveSettings(any()),
    ).thenAnswer((_) async {});

    settingsCubit = SettingsCubit(settingsRepository: mockSettingsRepository);

    // loadSettings is called in the constructor, ignore it in all tests.
    verify(() => mockSettingsRepository.loadSettings()).called(1);
  });

  final defaultSettings = Settings.defaultSettings();

  setUpAll(() {
    // Dummy value
    registerFallbackValue(defaultSettings);
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

  test('updateSettings updates the settings correctly', () {
    final generalSettings = defaultSettings.general.copyWith(
      useClassicMaterialDesign: false,
    );

    settingsCubit.updateSettings(general: generalSettings);
    final newExpectedSettings = settingsCubit.state.settingsOrThrow.copyWith(
      general: generalSettings,
    );

    verify(
      () => mockSettingsRepository.saveSettings(newExpectedSettings),
    ).called(1);

    verifyNoMoreInteractions(mockSettingsRepository);
  });
}
