import 'package:flutter/material.dart';
import 'package:kraft_launcher/settings/data/settings.dart';
import 'package:kraft_launcher/settings/data/settings_storage.dart';
import 'package:kraft_launcher/settings/ui/cubit/settings_cubit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockSettingsStorage extends Mock implements SettingsStorage {}

void main() {
  late MockSettingsStorage mockSettingsStorage;
  late SettingsCubit settingsCubit;
  late Settings existingSettings;

  setUp(() {
    mockSettingsStorage = MockSettingsStorage();
    existingSettings = const Settings(
      general: GeneralSettings(themeMode: ThemeMode.dark),
    );
    when(
      () => mockSettingsStorage.loadSettings(),
    ).thenAnswer((_) => existingSettings);
    settingsCubit = SettingsCubit(settingsStorage: mockSettingsStorage);
    verify(() => mockSettingsStorage.loadSettings()).called(1);
  });

  test('loads the settings initially', () {
    settingsCubit = SettingsCubit(settingsStorage: mockSettingsStorage);
    verify(() => mockSettingsStorage.loadSettings()).called(1);
    expect(settingsCubit.state.settings, existingSettings);
    verifyNoMoreInteractions(mockSettingsStorage);
  });

  test('loadSettings updates the settings correctly', () {
    existingSettings = const Settings(
      general: GeneralSettings(
        appLanguage: AppLanguage.de,
        useAccentColor: true,
      ),
    );
    when(
      () => mockSettingsStorage.loadSettings(),
    ).thenAnswer((_) => existingSettings);

    settingsCubit.loadSettings();

    verify(() => mockSettingsStorage.loadSettings()).called(1);
    expect(settingsCubit.state.settings, existingSettings);

    verifyNoMoreInteractions(mockSettingsStorage);
  });

  test('loadSettings preserves current UI state', () {
    const currentSelectedCategory = SettingsCategory.java;
    settingsCubit.updateSelectedCategory(currentSelectedCategory);

    expect(settingsCubit.state.selectedCategory, currentSelectedCategory);

    settingsCubit.loadSettings();

    expect(settingsCubit.state.selectedCategory, currentSelectedCategory);
  });

  test('updateSettings updates the settings correctly', () {
    const generalSettings = GeneralSettings(useClassicMaterialDesign: false);

    settingsCubit.updateSettings(general: generalSettings);
    final newExpectedSettings = settingsCubit.state.settings.copyWith(
      general: generalSettings,
    );
    verify(
      () => mockSettingsStorage.saveSettings(newExpectedSettings),
    ).called(1);
    verifyNoMoreInteractions(mockSettingsStorage);
  });
}
