import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:kraft_launcher/account/ui/account_switcher_icon_button.dart';
import 'package:kraft_launcher/account/ui/accounts_tab.dart';
import 'package:kraft_launcher/common/constants/project_info_constants.dart';
import 'package:kraft_launcher/common/generated/l10n/app_localizations.dart';
import 'package:kraft_launcher/common/logic/app_data_paths.dart';
import 'package:kraft_launcher/common/ui/utils/build_context_ext.dart';
import 'package:kraft_launcher/common/ui/utils/home_screen_tab_ext.dart';
import 'package:kraft_launcher/common/ui/widgets/optional_dynamic_color_builder.dart';
import 'package:kraft_launcher/common/ui/widgets/scaffold_with_tabs.dart';
import 'package:kraft_launcher/di.dart';
import 'package:kraft_launcher/launcher/ui/profile_tab.dart';
import 'package:kraft_launcher/settings/logic/settings.dart';
import 'package:kraft_launcher/settings/ui/cubit/settings_cubit.dart';
import 'package:kraft_launcher/settings/ui/settings_tab.dart';

final _router = GoRouter(
  routes: [GoRoute(path: '/', builder: (context, state) => const HomeScreen())],
);

class MainApp extends StatelessWidget {
  const MainApp({super.key, required this.appDataPaths});

  final AppDataPaths appDataPaths;

  @override
  Widget build(BuildContext context) {
    return AppDi(
      appDataPaths: appDataPaths,
      child: BlocSelector<SettingsCubit, SettingsState, GeneralSettings?>(
        selector: (state) => state.settings?.general,
        builder: (context, generalSettings) {
          if (generalSettings == null) {
            return const MaterialApp(
              home: Center(child: CircularProgressIndicator()),
            );
          }
          final listTileTheme = ListTileThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          );

          const progressIndicatorTheme = ProgressIndicatorThemeData(
            // ignore: deprecated_member_use
            year2023: false,
          );
          const sliderTheme = SliderThemeData(
            // ignore: deprecated_member_use
            year2023: false,
          );

          ColorScheme colorScheme(Brightness brightness) =>
              ColorScheme.fromSeed(
                seedColor: generalSettings.useAccentColor
                    ? Color(generalSettings.accentColor)
                    : Colors.lightBlue,
                brightness: brightness,
              );

          return OptionalDynamicColorBuilder(
            isEnabled: generalSettings.useDynamicColor,
            builder: (lightColorScheme, darkColorScheme) => MaterialApp.router(
              routerConfig: _router,
              title: ProjectInfoConstants.displayName,
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                useMaterial3: !generalSettings.useClassicMaterialDesign,
                colorScheme: lightColorScheme ?? colorScheme(Brightness.light),
                listTileTheme: listTileTheme,
                progressIndicatorTheme: progressIndicatorTheme,
                sliderTheme: sliderTheme,
              ),
              darkTheme: ThemeData(
                useMaterial3: !generalSettings.useClassicMaterialDesign,
                colorScheme: darkColorScheme ?? colorScheme(Brightness.dark),
                listTileTheme: listTileTheme,
                progressIndicatorTheme: progressIndicatorTheme,
                sliderTheme: sliderTheme,
              ),
              themeMode: switch (generalSettings.themeMode) {
                AppThemeMode.system => ThemeMode.system,
                AppThemeMode.light => ThemeMode.light,
                AppThemeMode.dark => ThemeMode.dark,
              },
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: generalSettings.appLanguage == AppLanguage.system
                  ? null
                  : Locale(generalSettings.appLanguage.localeCode),
            ),
          );
        },
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => ScaffoldWithTabs(
    defaultIndex: () {
      final defaultTab = context
          .read<SettingsCubit>()
          .state
          .settingsOrThrow
          .general
          .defaultTab;
      final index = HomeScreenTab.values.indexOf(defaultTab);
      return index;
    }(),
    navigationMenuItems: HomeScreenTab.values
        .map(
          (tab) => NavigationMenuItem(
            unselectedIcon: Icon(tab.unselectedIconData),
            selectedIcon: Icon(tab.selectedIconData),
            label: tab.getLabel(context.loc),
            body: switch (tab) {
              HomeScreenTab.profiles => const ProfileTab(),
              HomeScreenTab.accounts => const AccountsTab(),
              HomeScreenTab.settings => const SettingsTab(),
              HomeScreenTab.news => Center(child: Text(context.loc.news)),
            },
          ),
        )
        .toList(),
    trailingItems: const [AccountSwitcherIconButton(), SizedBox(height: 20)],
  );
}
