import 'package:equatable/equatable.dart';
import 'package:kraft_launcher/settings/logic/app_language.dart';
import 'package:meta/meta.dart';

export 'app_language.dart';

enum AppThemeMode { system, light, dark }

@immutable
class Settings extends Equatable {
  const Settings({required this.general});

  factory Settings.defaultSettings() => const Settings(
    general: GeneralSettings(
      accentColor: 0xFFFF5252, // Colors.redAccent
      themeMode: AppThemeMode.system,
      appLanguage: AppLanguage.system,
      defaultTab: HomeScreenTab.profiles,
      useAccentColor: false,
      useClassicMaterialDesign: false,
      useDynamicColor: true,
    ),
  );

  final GeneralSettings general;

  Settings copyWith({GeneralSettings? general}) =>
      Settings(general: general ?? this.general);

  @override
  List<Object?> get props => [general];
}

enum HomeScreenTab { news, profiles, accounts, settings }

@immutable
class GeneralSettings extends Equatable {
  const GeneralSettings({
    required this.themeMode,
    required this.appLanguage,
    required this.useDynamicColor,
    required this.useClassicMaterialDesign,
    required this.accentColor,
    required this.useAccentColor,
    required this.defaultTab,
  });

  final AppThemeMode themeMode;
  final AppLanguage appLanguage;
  final bool useDynamicColor;
  final bool useClassicMaterialDesign;
  final int accentColor; // Stored as ARGB int
  final bool useAccentColor;
  final HomeScreenTab defaultTab;

  @override
  List<Object?> get props => [
    themeMode,
    appLanguage,
    useDynamicColor,
    useClassicMaterialDesign,
    accentColor,
    useAccentColor,
    defaultTab,
  ];

  GeneralSettings copyWith({
    AppThemeMode? themeMode,
    AppLanguage? appLanguage,
    bool? useDynamicColor,
    bool? useClassicMaterialDesign,
    int? accentColor,
    bool? useAccentColor,
    HomeScreenTab? defaultTab,
  }) => GeneralSettings(
    themeMode: themeMode ?? this.themeMode,
    appLanguage: appLanguage ?? this.appLanguage,
    useDynamicColor: useDynamicColor ?? this.useDynamicColor,
    useClassicMaterialDesign:
        useClassicMaterialDesign ?? this.useClassicMaterialDesign,
    accentColor: accentColor ?? this.accentColor,
    useAccentColor: useAccentColor ?? this.useAccentColor,
    defaultTab: defaultTab ?? this.defaultTab,
  );
}
