import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kraft_launcher/account/data/launcher_minecraft_account/local_file_storage/file_account_storage.dart';
import 'package:kraft_launcher/account/data/launcher_minecraft_account/secure_storage/secure_account_storage.dart';
import 'package:kraft_launcher/account/data/microsoft_auth_api/microsoft_auth_api.dart';
import 'package:kraft_launcher/account/data/microsoft_auth_api/microsoft_auth_api_impl.dart';
import 'package:kraft_launcher/account/data/minecraft_account_api/minecraft_account_api.dart';
import 'package:kraft_launcher/account/data/minecraft_account_api/minecraft_account_api_impl.dart';
import 'package:kraft_launcher/account/logic/launcher_minecraft_account/account_repository.dart';
import 'package:kraft_launcher/account/logic/microsoft/auth_flows/auth_code/microsoft_auth_code_flow.dart';
import 'package:kraft_launcher/account/logic/microsoft/auth_flows/device_code/microsoft_device_code_flow.dart';
import 'package:kraft_launcher/account/logic/microsoft/auth_flows/microsoft_oauth_flow_controller.dart';
import 'package:kraft_launcher/account/logic/microsoft/minecraft/account_refresher/image_cache_service/default_image_cache_service.dart';
import 'package:kraft_launcher/account/logic/microsoft/minecraft/account_refresher/minecraft_account_refresher.dart';
import 'package:kraft_launcher/account/logic/microsoft/minecraft/account_resolver/minecraft_account_resolver.dart';
import 'package:kraft_launcher/account/logic/microsoft/minecraft/account_service/minecraft_account_service.dart';
import 'package:kraft_launcher/account/logic/offline_account/minecraft_offline_account_factory.dart';
import 'package:kraft_launcher/account/logic/platform_secure_storage_support.dart';
import 'package:kraft_launcher/account/ui/account_cubit/account_cubit.dart';
import 'package:kraft_launcher/account/ui/account_switcher_icon_button.dart';
import 'package:kraft_launcher/account/ui/accounts_tab.dart';
import 'package:kraft_launcher/account/ui/microsoft_auth_cubit/microsoft_auth_cubit.dart';
import 'package:kraft_launcher/common/constants/project_info_constants.dart';
import 'package:kraft_launcher/common/generated/l10n/app_localizations.dart';
import 'package:kraft_launcher/common/logic/app_data_paths.dart';
import 'package:kraft_launcher/common/logic/app_logger.dart';
import 'package:kraft_launcher/common/logic/dio_client.dart';
import 'package:kraft_launcher/common/ui/utils/build_context_ext.dart';
import 'package:kraft_launcher/common/ui/utils/home_screen_tab_ext.dart';
import 'package:kraft_launcher/common/ui/widgets/optional_dynamic_color_builder.dart';
import 'package:kraft_launcher/common/ui/widgets/scaffold_with_tabs.dart';
import 'package:kraft_launcher/launcher/ui/profile_tab.dart';
import 'package:kraft_launcher/settings/data/file_settings_storage.dart';
import 'package:kraft_launcher/settings/logic/settings.dart';
import 'package:kraft_launcher/settings/logic/settings_repository.dart';
import 'package:kraft_launcher/settings/ui/cubit/settings_cubit.dart';
import 'package:kraft_launcher/settings/ui/settings_tab.dart';
import 'package:path_provider/path_provider.dart';

// TODO: Replace all occurrences of Enum.values.firstWhere(...) with Enum.byName(...)
//  because Enum.byName is a built-in, more efficient, and safer way to get enum
//  values by their name string. It avoids manual iteration and potential errors.
// TODO: Read: https://dart.dev/tools/linter-rules/avoid_slow_async_io, review all usages of file sync operations

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppDataPaths.instance = AppDataPaths(
    // TODO: Support portable mode, run in portable mode on debug-builds
    workingDirectory:
        kDebugMode
            ? (Directory('devWorkingDirectory')..createSync(recursive: true))
            : await getApplicationSupportDirectory(),
  );
  AppLogger.init();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.recordError(details.exceptionAsString());
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.recordError(error.toString());

    return false;
  };

  runApp(const MainApp());
}

final _router = GoRouter(
  routes: [GoRoute(path: '/', builder: (context, state) => const HomeScreen())],
);

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return di(
      child: blocProviders(
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
                  seedColor:
                      generalSettings.useAccentColor
                          ? Color(generalSettings.accentColor)
                          : Colors.lightBlue,
                  brightness: brightness,
                );

            return OptionalDynamicColorBuilder(
              isEnabled: generalSettings.useDynamicColor,
              builder:
                  (lightColorScheme, darkColorScheme) => MaterialApp.router(
                    routerConfig: _router,
                    title: ProjectInfoConstants.displayName,
                    debugShowCheckedModeBanner: false,
                    theme: ThemeData(
                      useMaterial3: !generalSettings.useClassicMaterialDesign,
                      colorScheme:
                          lightColorScheme ?? colorScheme(Brightness.light),
                      listTileTheme: listTileTheme,
                      progressIndicatorTheme: progressIndicatorTheme,
                      sliderTheme: sliderTheme,
                    ),
                    darkTheme: ThemeData(
                      useMaterial3: !generalSettings.useClassicMaterialDesign,
                      colorScheme:
                          darkColorScheme ?? colorScheme(Brightness.dark),
                      listTileTheme: listTileTheme,
                      progressIndicatorTheme: progressIndicatorTheme,
                      sliderTheme: sliderTheme,
                    ),
                    themeMode: switch (generalSettings.themeMode) {
                      AppThemeMode.system => ThemeMode.system,
                      AppThemeMode.light => ThemeMode.light,
                      AppThemeMode.dark => ThemeMode.dark,
                    },
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    supportedLocales: AppLocalizations.supportedLocales,
                    locale:
                        generalSettings.appLanguage == AppLanguage.system
                            ? null
                            : Locale(generalSettings.appLanguage.localeCode),
                  ),
            );
          },
        ),
      ),
    );
  }

  Widget di({required Widget child}) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<MicrosoftAuthApi>(
        create: (context) => MicrosoftAuthApiImpl(dio: DioClient.instance),
      ),
      RepositoryProvider<MinecraftAccountApi>(
        create: (context) => MinecraftAccountApiImpl(dio: DioClient.instance),
      ),
      RepositoryProvider<PlatformSecureStorageSupport>(
        create: (context) => PlatformSecureStorageSupport(),
      ),
      RepositoryProvider<AccountRepository>(
        create:
            (context) => AccountRepository(
              fileAccountStorage: FileAccountStorage.fromAppDataPaths(
                AppDataPaths.instance,
              ),
              secureAccountStorage: SecureAccountStorage(
                flutterSecureStorage: const FlutterSecureStorage(),
              ),
              secureStorageSupport: context.read(),
            ),
      ),
      RepositoryProvider<MinecraftAccountResolver>(
        create:
            (context) => MinecraftAccountResolver(
              microsoftAuthApi: context.read(),
              minecraftAccountApi: context.read(),
            ),
      ),
      RepositoryProvider<MinecraftAccountService>(
        create:
            (context) => MinecraftAccountService(
              accountRepository: context.read<AccountRepository>(),
              microsoftOAuthFlowController: MicrosoftOAuthFlowController(
                microsoftAuthCodeFlow: MicrosoftAuthCodeFlow(
                  microsoftAuthApi: context.read(),
                ),
                microsoftDeviceCodeFlow: MicrosoftDeviceCodeFlow(
                  microsoftAuthApi: context.read(),
                ),
              ),
              minecraftAccountResolver: context.read(),
              minecraftAccountRefresher: MinecraftAccountRefresher(
                imageCacheService: DefaultImageCacheService(),
                microsoftAuthApi: context.read(),
                minecraftAccountApi: context.read(),
                accountResolver: context.read(),
              ),
            ),
      ),
      RepositoryProvider(create: (context) => ImagePicker()),
    ],
    child: child,
  );

  Widget blocProviders({required Widget child}) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create:
            (context) => AccountCubit(
              accountRepository: context.read(),
              offlineAccountFactory: MinecraftOfflineAccountFactory(),
            ),
      ),
      BlocProvider(
        create:
            (context) => MicrosoftAuthCubit(
              minecraftAccountService: context.read(),
              // TODO: No bloc/cubit should depends on the other, avoid? See: https://bloclibrary.dev/architecture/#bloc-to-bloc-communication,
              //  See also: https://bloclibrary.dev/architecture/#connecting-blocs-through-domain and AccountRepository, this should be fixed once other related TODOs are fixed in AccountCubit and MicrosoftAuthCubit
              accountCubit: context.read(),
              secureStorageSupport: context.read(),
            ),
      ),
      BlocProvider(
        create:
            (context) => SettingsCubit(
              settingsRepository: SettingsRepository(
                fileSettingsStorage: FileSettingsStorage.fromAppDataPaths(
                  AppDataPaths.instance,
                ),
              ),
            ),
        lazy: true,
      ),
    ],
    child: child,
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => ScaffoldWithTabs(
    defaultIndex: () {
      final defaultTab =
          context
              .read<SettingsCubit>()
              .state
              .settingsOrThrow
              .general
              .defaultTab;
      final index = HomeScreenTab.values.indexOf(defaultTab);
      return index;
    }(),
    navigationMenuItems:
        HomeScreenTab.values
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
