import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'account/data/microsoft_auth_api/microsoft_auth_api.dart';
import 'account/data/microsoft_auth_api/microsoft_auth_api_impl.dart';
import 'account/data/minecraft_account/local_file_storage/file_account_storage.dart';
import 'account/data/minecraft_account/secure_storage/secure_account_storage.dart';
import 'account/data/minecraft_account_api/minecraft_account_api.dart';
import 'account/data/minecraft_account_api/minecraft_account_api_impl.dart';
import 'account/logic/account_cubit/account_cubit.dart';
import 'account/logic/account_repository.dart';
import 'account/logic/microsoft/auth_flows/auth_code/microsoft_auth_code_flow.dart';
import 'account/logic/microsoft/auth_flows/device_code/microsoft_device_code_flow.dart';
import 'account/logic/microsoft/cubit/microsoft_account_handler_cubit.dart';
import 'account/logic/microsoft/microsoft_oauth_flow_controller.dart';
import 'account/logic/microsoft/minecraft/account_refresher/image_cache_service/default_image_cache_service.dart';
import 'account/logic/microsoft/minecraft/account_refresher/minecraft_account_refresher.dart';
import 'account/logic/microsoft/minecraft/account_resolver/minecraft_account_resolver.dart';
import 'account/logic/microsoft/minecraft/account_service/minecraft_account_service.dart';
import 'account/logic/offline_account/minecraft_offline_account_factory.dart';
import 'account/logic/platform_secure_storage_support.dart';
import 'account/ui/account_switcher_icon_button.dart';
import 'account/ui/accounts_tab.dart';
import 'common/constants/project_info_constants.dart';
import 'common/generated/l10n/app_localizations.dart';
import 'common/logic/app_data_paths.dart';
import 'common/logic/app_logger.dart';
import 'common/logic/dio_client.dart';
import 'common/ui/utils/build_context_ext.dart';
import 'common/ui/utils/home_screen_tab_ext.dart';
import 'common/ui/widgets/optional_dynamic_color_builder.dart';
import 'common/ui/widgets/scaffold_with_tabs.dart';
import 'profile/profile_tab.dart';
import 'settings/data/settings.dart';
import 'settings/data/settings_storage.dart';
import 'settings/logic/cubit/settings_cubit.dart';
import 'settings/ui/settings_tab.dart';

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
        child: BlocBuilder<SettingsCubit, SettingsState>(
          buildWhen:
              (previous, current) =>
                  previous.settings.general != current.settings.general,
          builder: (context, state) {
            final generalSettings = state.settings.general;
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
                          ? generalSettings.accentColor
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
                    themeMode: generalSettings.themeMode,
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
      RepositoryProvider<MicrosoftAuthApi>.value(
        value: MicrosoftAuthApiImpl(dio: DioClient.instance),
      ),
      RepositoryProvider<MinecraftAccountApi>.value(
        value: MinecraftAccountApiImpl(dio: DioClient.instance),
      ),
      RepositoryProvider<AccountRepository>.value(
        value: AccountRepository(
          fileAccountStorage: FileAccountStorage.fromAppDataPaths(
            AppDataPaths.instance,
          ),
          secureAccountStorage: SecureAccountStorage(
            flutterSecureStorage: const FlutterSecureStorage(),
          ),
          secureStorageSupport: PlatformSecureStorageSupport(),
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
      RepositoryProvider.value(value: ImagePicker()),
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
            (context) => MicrosoftAccountHandlerCubit(
              minecraftAccountService: context.read(),
              // TODO: No bloc/cubit should depends on the other, avoid? See: https://bloclibrary.dev/architecture/#bloc-to-bloc-communication,
              //  See also: https://bloclibrary.dev/architecture/#connecting-blocs-through-domain and AccountRepository, this should be fixed once other related TODOs are fixed in MinecraftAccountManager, AccountCubit and MicrosoftAccountHandlerCubit
              accountCubit: context.read<AccountCubit>(),
            ),
      ),
      BlocProvider(
        create:
            (context) => SettingsCubit(
              settingsStorage: SettingsStorage.fromAppDataPaths(
                AppDataPaths.instance,
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
          context.read<SettingsCubit>().state.settings.general.defaultTab;
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
