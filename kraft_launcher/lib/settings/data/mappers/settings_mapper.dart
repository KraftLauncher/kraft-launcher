import 'package:kraft_launcher/settings/data/file_settings.dart';
import 'package:kraft_launcher/settings/logic/settings.dart';

extension SettingsMapper on Settings {
  FileSettings toFileDto() => FileSettings(
    general: () {
      final general = this.general;
      return FileGeneralSettings(
        themeMode: switch (general.themeMode) {
          AppThemeMode.system => FileAppThemeMode.system,
          AppThemeMode.light => FileAppThemeMode.light,
          AppThemeMode.dark => FileAppThemeMode.dark,
        },
        appLanguage: switch (general.appLanguage) {
          AppLanguage.system => FileAppLanguage.system,
          AppLanguage.en => FileAppLanguage.en,
          AppLanguage.de => FileAppLanguage.de,
          AppLanguage.ar => FileAppLanguage.ar,
          AppLanguage.zh => FileAppLanguage.zh,
        },
        useDynamicColor: general.useDynamicColor,
        useClassicMaterialDesign: general.useClassicMaterialDesign,
        accentColor: general.accentColor,
        useAccentColor: general.useAccentColor,
        defaultTab: switch (general.defaultTab) {
          HomeScreenTab.news => FileHomeScreenTab.news,
          HomeScreenTab.profiles => FileHomeScreenTab.profiles,
          HomeScreenTab.accounts => FileHomeScreenTab.accounts,
          HomeScreenTab.settings => FileHomeScreenTab.settings,
        },
      );
    }(),
  );
}
