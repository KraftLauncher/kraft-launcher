import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show Color, Colors, ThemeMode;
import 'package:meta/meta.dart';

import '../../common/logic/json.dart';
import 'app_language.dart';
export 'app_language.dart';

@immutable
class Settings extends Equatable {
  const Settings({this.general = const GeneralSettings()});

  factory Settings.fromJson(JsonObject json) => Settings(
    general: GeneralSettings.fromJson((json['general'] as JsonObject?) ?? {}),
  );

  final GeneralSettings general;

  JsonObject toJson() => {'general': general.toJson()};

  Settings copyWith({GeneralSettings? general}) =>
      Settings(general: general ?? this.general);

  @override
  List<Object?> get props => [general];
}

enum HomeScreenTab { news, profiles, accounts, settings }

@immutable
class GeneralSettings extends Equatable {
  const GeneralSettings({
    this.themeMode = ThemeMode.system,
    this.appLanguage = AppLanguage.system,
    this.useDynamicColor = true,
    this.useClassicMaterialDesign = false,
    this.accentColor = Colors.redAccent,
    this.useAccentColor = false,
    this.defaultTab = HomeScreenTab.profiles,
  });

  factory GeneralSettings.fromJson(JsonObject json) => GeneralSettings(
    appLanguage: AppLanguage.values.firstWhere(
      (language) => language.name == json['appLanguage'] as String?,
      orElse: () => AppLanguage.system,
    ),
    themeMode: ThemeMode.values.firstWhere(
      (themeMode) => themeMode.name == json['themeMode'] as String?,
      orElse: () => ThemeMode.system,
    ),
    useDynamicColor: (json['useDynamicColor'] as bool?) ?? true,
    useClassicMaterialDesign:
        (json['useClassicMaterialDesign'] as bool?) ?? false,
    accentColor: Color(
      (json['accentColor'] as int?) ?? Colors.redAccent.toARGB32(),
    ),
    useAccentColor: (json['useAccentColor'] as bool?) ?? false,
    defaultTab: HomeScreenTab.values.firstWhere(
      (tab) => (json['defaultTab'] as String?) == tab.name,
      orElse: () => HomeScreenTab.profiles,
    ),
  );

  final ThemeMode themeMode;
  final AppLanguage appLanguage;
  final bool useDynamicColor;
  final bool useClassicMaterialDesign;
  final Color accentColor;
  final bool useAccentColor;
  final HomeScreenTab defaultTab;

  JsonObject toJson() => {
    'themeMode': themeMode.name,
    'appLanguage': appLanguage.name,
    'useDynamicColor': useDynamicColor,
    'useClassicMaterialDesign': useClassicMaterialDesign,
    'accentColor': accentColor.toARGB32(),
    'useAccentColor': useAccentColor,
    'defaultTab': defaultTab.name,
  };

  @override
  List<Object?> get props => [
    themeMode,
    appLanguage,
    useDynamicColor,
    useClassicMaterialDesign,
    accentColor.toARGB32(),
    useAccentColor,
    defaultTab,
  ];

  GeneralSettings copyWith({
    ThemeMode? themeMode,
    AppLanguage? appLanguage,
    bool? useDynamicColor,
    bool? useClassicMaterialDesign,
    Color? accentColor,
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
