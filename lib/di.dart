import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
import 'package:kraft_launcher/account/logic/microsoft/minecraft/account_refresher/image_cache_service/image_cache_service.dart';
import 'package:kraft_launcher/account/logic/microsoft/minecraft/account_refresher/minecraft_account_refresher.dart';
import 'package:kraft_launcher/account/logic/microsoft/minecraft/account_resolver/minecraft_account_resolver.dart';
import 'package:kraft_launcher/account/logic/microsoft/minecraft/account_service/minecraft_account_service.dart';
import 'package:kraft_launcher/account/logic/offline_account/minecraft_offline_account_factory.dart';
import 'package:kraft_launcher/account/logic/platform_secure_storage_support.dart';
import 'package:kraft_launcher/account/ui/account_cubit/account_cubit.dart';
import 'package:kraft_launcher/account/ui/microsoft_auth_cubit/microsoft_auth_cubit.dart';
import 'package:kraft_launcher/common/logic/app_data_paths.dart';
import 'package:kraft_launcher/common/logic/dio_client.dart';
import 'package:kraft_launcher/settings/data/file_settings_storage.dart';
import 'package:kraft_launcher/settings/logic/settings_repository.dart';
import 'package:kraft_launcher/settings/ui/cubit/settings_cubit.dart';
import 'package:meta/meta.dart';
// Provider is used for dependency injection, not state management.
// ignore: depend_on_referenced_packages
import 'package:provider/provider.dart'
    show MultiProvider, Provider, ReadContext;

class AppDi extends StatelessWidget {
  const AppDi({super.key, required this.child, required this.appDataPaths});

  final Widget child;
  final AppDataPaths appDataPaths;

  @override
  Widget build(BuildContext context) {
    return _CommonProviders(
      appDataPaths: appDataPaths,
      child: _AccountFeatureProviders(
        child: _SettingsFeatureProviders(child: child),
      ),
    );
  }
}

class _CommonProviders extends StatelessWidget {
  const _CommonProviders({required this.child, required this.appDataPaths});

  final Widget child;
  final AppDataPaths appDataPaths;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (context) => ImagePicker()),
        Provider(create: (context) => const FlutterSecureStorage()),
        Provider.value(value: appDataPaths),
      ],
      child: child,
    );
  }
}

abstract class _FeatureProviders extends StatelessWidget {
  const _FeatureProviders({required this.child});

  final Widget child;

  @nonVirtual
  @override
  Widget build(BuildContext context) =>
      _dataLayer(child: _logicLayer(child: _uiLayer(child: child)));

  Widget _dataLayer({required Widget child});
  Widget _logicLayer({required Widget child});
  Widget _uiLayer({required Widget child});
}

// NOTE: The difference between RepositoryProvider and Provider is semantic.

class _AccountFeatureProviders extends _FeatureProviders {
  const _AccountFeatureProviders({required super.child});

  @override
  Widget _dataLayer({required Widget child}) => MultiProvider(
    providers: [
      Provider<MicrosoftAuthApi>(
        create: (context) => MicrosoftAuthApiImpl(dio: DioClient.instance),
      ),
      Provider<MinecraftAccountApi>(
        create: (context) => MinecraftAccountApiImpl(dio: DioClient.instance),
      ),
      Provider<PlatformSecureStorageSupport>(
        create: (context) => PlatformSecureStorageSupport(),
      ),
      RepositoryProvider<ImageCacheService>(
        create: (context) => DefaultImageCacheService(),
      ),
      RepositoryProvider<FileAccountStorage>(
        create:
            (context) => FileAccountStorage.fromAppDataPaths(context.read()),
      ),
      RepositoryProvider(
        create:
            (context) =>
                SecureAccountStorage(flutterSecureStorage: context.read()),
      ),
    ],
    child: child,
  );

  @override
  Widget _logicLayer({required Widget child}) => MultiProvider(
    providers: [
      RepositoryProvider<AccountRepository>(
        create:
            (context) => AccountRepository(
              fileAccountStorage: context.read(),
              secureAccountStorage: context.read(),
              secureStorageSupport: context.read(),
            ),
      ),
      Provider<MinecraftAccountResolver>(
        create:
            (context) => MinecraftAccountResolver(
              microsoftAuthApi: context.read(),
              minecraftAccountApi: context.read(),
            ),
      ),
      Provider<MinecraftAccountService>(
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
                imageCacheService: context.read(),
                microsoftAuthApi: context.read(),
                minecraftAccountApi: context.read(),
                accountResolver: context.read(),
              ),
            ),
      ),
      Provider(create: (context) => MinecraftOfflineAccountFactory()),
    ],
    child: child,
  );

  @override
  Widget _uiLayer({required Widget child}) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create:
            (context) => AccountCubit(
              accountRepository: context.read(),
              offlineAccountFactory: context.read(),
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
    ],
    child: child,
  );
}

class _SettingsFeatureProviders extends _FeatureProviders {
  const _SettingsFeatureProviders({required super.child});

  @override
  Widget _dataLayer({required Widget child}) => MultiProvider(
    providers: [
      Provider(
        create:
            (context) => FileSettingsStorage.fromAppDataPaths(context.read()),
      ),
    ],
    child: child,
  );

  @override
  Widget _logicLayer({required Widget child}) => MultiProvider(
    providers: [
      Provider(
        create:
            (context) =>
                SettingsRepository(fileSettingsStorage: context.read()),
      ),
    ],
    child: child,
  );

  @override
  Widget _uiLayer({required Widget child}) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (context) => SettingsCubit(settingsRepository: context.read()),
        lazy: true,
      ),
    ],
    child: child,
  );
}
