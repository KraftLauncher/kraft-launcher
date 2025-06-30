import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:kraft_launcher/settings/data/settings.dart';
import 'package:kraft_launcher/settings/data/settings_storage.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({required this.settingsStorage})
    : super(const SettingsState()) {
    loadSettings();
  }

  final SettingsStorage settingsStorage;

  void updateSelectedCategory(SettingsCategory newCategory) =>
      emit(state.copyWith(selectedCategory: newCategory));

  void loadSettings() {
    final settings = settingsStorage.loadSettings();
    emit(state.copyWith(settings: settings));
  }

  void updateSettings({GeneralSettings? general}) {
    final settings = state.settings.copyWith(general: general);
    emit(state.copyWith(settings: settings));
    settingsStorage.saveSettings(settings);
  }
}
