import 'package:equatable/equatable.dart';
import 'package:kraft_launcher/common/logic/json.dart';
import 'package:meta/meta.dart';

export '../logic/app_language.dart';

@immutable
class FileSettings extends Equatable {
  const FileSettings({required this.general});

  factory FileSettings.fromJson(JsonMap json) => FileSettings(
    general: FileGeneralSettings.fromJson((json['general'] as JsonMap?) ?? {}),
  );

  final FileGeneralSettings general;

  JsonMap toJson() => {'general': general.toJson()};

  @override
  List<Object?> get props => [general];
}

enum FileHomeScreenTab { news, profiles, accounts, settings }

enum FileAppThemeMode { system, light, dark }

enum FileAppLanguage {
  system(jsonValue: 'system'),
  en(jsonValue: 'en'),
  de(jsonValue: 'de'),
  ar(jsonValue: 'ar'),
  zh(jsonValue: 'zh');

  const FileAppLanguage({required this.jsonValue});

  final String jsonValue;
}

@immutable
class FileGeneralSettings extends Equatable {
  const FileGeneralSettings({
    required this.themeMode,
    required this.appLanguage,
    required this.useDynamicColor,
    required this.useClassicMaterialDesign,
    required this.accentColor,
    required this.useAccentColor,
    required this.defaultTab,
  });

  factory FileGeneralSettings.fromJson(JsonMap json) => FileGeneralSettings(
    appLanguage: FileAppLanguage.values.byName(json['appLanguage']! as String),
    themeMode: FileAppThemeMode.values.byName(json['themeMode']! as String),
    useDynamicColor: json['useDynamicColor']! as bool,
    useClassicMaterialDesign: json['useClassicMaterialDesign']! as bool,
    accentColor: json['accentColor']! as int,
    useAccentColor: json['useAccentColor']! as bool,
    defaultTab: FileHomeScreenTab.values.byName(json['defaultTab']! as String),
  );

  final FileAppThemeMode themeMode;
  final FileAppLanguage appLanguage;
  final bool useDynamicColor;
  final bool useClassicMaterialDesign;
  final int accentColor; // Stored as ARGB int
  final bool useAccentColor;
  final FileHomeScreenTab defaultTab;

  JsonMap toJson() => {
    'themeMode': themeMode.name,
    'appLanguage': appLanguage.jsonValue,
    'useDynamicColor': useDynamicColor,
    'useClassicMaterialDesign': useClassicMaterialDesign,
    'accentColor': accentColor,
    'useAccentColor': useAccentColor,
    'defaultTab': defaultTab.name,
  };

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
}
