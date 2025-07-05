import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:kraft_launcher/settings/logic/settings.dart';
import 'package:kraft_launcher/settings/logic/settings_repository.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({required this.settingsRepository})
    : super(const SettingsState()) {
    loadSettings();
  }

  final SettingsRepository settingsRepository;

  void updateSelectedCategory(SettingsCategory newCategory) =>
      emit(state.copyWith(selectedCategory: newCategory));

  Future<void> loadSettings() async {
    final settings = await settingsRepository.loadSettings();
    emit(state.copyWith(settings: settings));
  }

  // TODO: COMPLETE FULLY, whether we should use settings from repository or cubit as single source of truth to update existing with new fields
  Future<void> updateSettings({GeneralSettings? general}) async {
    final initialSettings = state.settings;
    if (initialSettings == null) {
      throw StateError(
        'Cannot update the settings until they have been loaded.',
      );
    }

    final settings = initialSettings.copyWith(general: general);
    emit(state.copyWith(settings: settings));
    await settingsRepository.saveSettings(settings);
  }
}
