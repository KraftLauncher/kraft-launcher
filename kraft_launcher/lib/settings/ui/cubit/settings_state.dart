part of 'settings_cubit.dart';

enum SettingsCategory { general, launcher, java, advanced, about }

final class SettingsState extends Equatable {
  const SettingsState({
    this.settings,
    this.selectedCategory = SettingsCategory.general,
  });

  // Null while loading.
  final Settings? settings;
  final SettingsCategory selectedCategory;

  Settings get settingsOrThrow =>
      settings ??
      (throw StateError(
        'The settings should be be loaded and not null at this point.',
      ));

  @override
  List<Object?> get props => [settings, selectedCategory];

  SettingsState copyWith({
    Settings? settings,
    SettingsCategory? selectedCategory,
  }) => SettingsState(
    settings: settings ?? this.settings,
    selectedCategory: selectedCategory ?? this.selectedCategory,
  );
}
