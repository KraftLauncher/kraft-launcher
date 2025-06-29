part of 'settings_cubit.dart';

enum SettingsCategory { general, launcher, java, advanced, about }

final class SettingsState extends Equatable {
  const SettingsState({
    this.settings = const Settings(),
    this.selectedCategory = SettingsCategory.general,
  });

  final Settings settings;
  final SettingsCategory selectedCategory;

  @override
  List<Object> get props => [settings, selectedCategory];

  SettingsState copyWith({
    Settings? settings,
    SettingsCategory? selectedCategory,
  }) => SettingsState(
    settings: settings ?? this.settings,
    selectedCategory: selectedCategory ?? this.selectedCategory,
  );
}
