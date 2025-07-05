import 'package:kraft_launcher/settings/data/file_settings.dart';
import 'package:kraft_launcher/settings/logic/settings.dart';

extension FileSettingsMapper on FileSettings {
  Settings toAppModel() => Settings(
    general: () {
      final general = this.general;
      return GeneralSettings(
        themeMode: switch (general.themeMode) {
          FileAppThemeMode.system => AppThemeMode.system,
          FileAppThemeMode.light => AppThemeMode.light,
          FileAppThemeMode.dark => AppThemeMode.dark,
        },
        appLanguage: switch (general.appLanguage) {
          FileAppLanguage.system => AppLanguage.system,
          FileAppLanguage.en => AppLanguage.en,
          FileAppLanguage.de => AppLanguage.de,
          FileAppLanguage.ar => AppLanguage.ar,
          FileAppLanguage.zh => AppLanguage.zh,
        },
        useDynamicColor: general.useDynamicColor,
        useClassicMaterialDesign: general.useClassicMaterialDesign,
        accentColor: general.accentColor,
        useAccentColor: general.useAccentColor,
        defaultTab: switch (general.defaultTab) {
          FileHomeScreenTab.news => HomeScreenTab.news,
          FileHomeScreenTab.profiles => HomeScreenTab.profiles,
          FileHomeScreenTab.accounts => HomeScreenTab.accounts,
          FileHomeScreenTab.settings => HomeScreenTab.settings,
        },
      );
    }(),
  );
}
