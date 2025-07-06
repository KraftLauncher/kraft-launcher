// ignore_for_file: avoid_print, require_trailing_commas

// NOTE: The code of this file was implemented very quickly for prototyping,
// the code is far from being production ready and this will be replaced entirely
// later to implement it properly. The goal is to understand how the launch work
// to plan it properly.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file_executable/file_executable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kraft_launcher/account/logic/launcher_minecraft_account/minecraft_account.dart';
import 'package:kraft_launcher/account/ui/account_cubit/account_cubit.dart';
import 'package:kraft_launcher/common/constants/constants.dart';
import 'package:kraft_launcher/common/constants/project_info_constants.dart';
import 'package:kraft_launcher/common/logic/app_data_paths.dart';
import 'package:kraft_launcher/common/logic/dio_client.dart';
import 'package:kraft_launcher/common/logic/dio_helpers.dart';
import 'package:kraft_launcher/common/logic/json.dart'
    show JsonList, JsonMap, jsonEncodePretty;
import 'package:kraft_launcher/common/models/either.dart';
import 'package:kraft_launcher/common/ui/utils/build_context_ext.dart';
import 'package:kraft_launcher/common/ui/utils/scaffold_messenger_ext.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/cache/minecraft_version_details_file_cache.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/cache/minecraft_versions_file_cache.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/minecraft_versions_api.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/models/asset_index/api_minecraft_asset_index.dart';
import 'package:kraft_launcher/launcher/logic/minecraft_versions/minecraft_versions_repository.dart';
import 'package:kraft_launcher/launcher/logic/minecraft_versions/models/version_details/minecraft_version_args.dart';
import 'package:path/path.dart' as p;
import 'package:pool/pool.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  // NOTE: The code of this file was implemented very quickly for prototyping,
  // the code is far from being production ready and this will be replaced entirely
  // later to implement it properly. The goal is to understand how the launch work
  // to plan it properly.

  static const javaRuntimesUrl =
      'https://launchermeta.mojang.com/v1/products/java-runtime/2ec0cc96c44e5a76b9c8b7c39df7210883d12871/all.json';

  // Also see https://launchermeta.mojang.com/v1/products/java-runtime/2ec0cc96c44e5a76b9c8b7c39df7210883d12871/all.json
  // and https://gist.github.com/skyrising/95a8e6a7287634e097ecafa2f21c240f

  final _versionController = TextEditingController();
  var _isLoading = false;

  @override
  void initState() {
    super.initState();
    _versionController.text = '1.21.7';
  }

  @override
  void dispose() {
    _versionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'IMPORTANT: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                TextSpan(
                  text:
                      'This implementation is temporary and intended solely for early development and testing purposes. '
                      'It is not final and will be completely replaced in future updates. '
                      'This applies to the current implementation of the profile feature, Minecraft launcher, installer. BREAKING CHANGES WILL OCCUR.',
                ),
              ],
            ),
          ),
          TextField(
            controller: _versionController,
            decoration: const InputDecoration(
              labelText: 'Minecraft Version',
              hintText: 'E.g., 1.20.1',
            ),
          ),
          FilledButton(
            onPressed: () async {
              final accountCubit = context.read<AccountCubit>();
              final defaultAccount = accountCubit.state.accounts.defaultAccount;

              if (defaultAccount == null ||
                  !(defaultAccount.ownsMinecraftJava ?? false)) {
                unawaited(
                  context.scaffoldMessenger.showSnackBarText(
                    'Please update the default account to an account that has a valid copy of Minecraft Java game.',
                  ),
                );
                return;
              }

              setState(() {
                _isLoading = true;
              });
              try {
                await launchGame(account: defaultAccount);
              } finally {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              }
            },
            child: const Text('Play'),
          ),
        ],
      ),
    );
  }

  // NOTE: This is dummy code and will be replaced fully later, it's for prototyping only
  // and not final.
  Future<void> launchGame({required MinecraftAccount account}) async {
    final appDataPaths = context.read<AppDataPaths>();
    final mcDirPath = appDataPaths.game.path;
    print('MC Dir: ${File(mcDirPath).absolute.path}');
    final librariesDirPath = p.join(mcDirPath, 'libraries');
    final assetsDirPath = p.join(mcDirPath, 'assets');
    final javaRuntimesDirPath = appDataPaths.runtimes;

    final gameDir = Directory(
      p.join(
        // ignore: invalid_use_of_visible_for_testing_member
        appDataPaths.workingDirectory.path,
        'single_instance',
      ),
    );
    if (!gameDir.existsSync()) {
      gameDir.createSync(recursive: true);
    }
    final nativesTempDir = Directory(p.join(mcDirPath, 'natives'));

    if (!nativesTempDir.existsSync()) {
      nativesTempDir.createSync(recursive: true);
    }

    if (!javaRuntimesDirPath.existsSync()) {
      javaRuntimesDirPath.createSync(recursive: true);
    }

    final osName = switch (defaultTargetPlatform) {
      TargetPlatform.linux => 'linux',
      TargetPlatform.macOS => 'osx',
      TargetPlatform.windows => 'windows',
      TargetPlatform.android => throw UnimplementedError(),
      TargetPlatform.fuchsia => throw UnimplementedError(),
      TargetPlatform.iOS => throw UnimplementedError(),
    };

    print('Fetching version manifest...');

    final dio = DioClient.instance;
    final minecraftVersionsApi = MinecraftVersionsApi(dio: dio);
    final minecraftVersionsRepository = MinecraftVersionsRepository(
      minecraftVersionsApi: minecraftVersionsApi,
      minecraftVersionsFileCache: MinecraftVersionsFileCache.fromAppDataPaths(
        appDataPaths,
      ),
      minecraftVersionDetailsFileCache:
          MinecraftVersionDetailsFileCache.fromAppDataPaths(appDataPaths),
    );

    final versionManifest =
        (await minecraftVersionsRepository.fetchVersionManifest()).valueOrThrow;
    final versions = versionManifest.versions;
    final version = versions.firstWhere(
      (version) => version.id == _versionController.text,
    );
    final versionUrl = version.detailsUrl;
    final versionId = version.id;

    print('Fetching version details...');

    final versionDetails =
        (await minecraftVersionsRepository.fetchVersionDetails(
          versionUrl,
          versionId: versionId,
        )).valueOrThrow;
    final versionArguments =
        versionDetails.arguments ??
        (throw UnimplementedError(
          'Older Minecraft versions are not supported right now, this is a prototype.',
        ));

    final mainClass = versionDetails.mainClass;

    final unhandledGameArguments = versionArguments.game;
    final gameArguments = <String>[];
    final classpath = <String>[];

    for (final either in unhandledGameArguments) {
      // Each item can be a Map or String
      switch (either) {
        case EitherLeft<String, MinecraftConditionalArg>():
          final argument = either.leftValue;

          if (argument.startsWith(r'${') && argument.endsWith('}')) {
            final argumentName = argument
                .replaceFirst(r'${', '')
                .replaceAll('}', '');
            final map = <String, String?>{
              'auth_player_name': account.username,
              'version_name': versionId,
              'game_directory': gameDir.absolute.path,
              'assets_root': File(assetsDirPath).absolute.path,
              'assets_index_name': versionDetails.assetsVersion,
              'auth_uuid': account.id,
              'auth_access_token':
                  account.microsoftAccountInfo!.minecraftAccessToken.value,
              // Not a TO-DO: maybe we should store these account fields just in case they are needed?
              'clientid': 'null',
              'auth_xuid': '0',
              'user_type': 'msa',
              'version_type': versionDetails.type.toLaunchArgument(),
            };
            final argumentValue =
                map.entries
                    .firstWhereOrNull((e) => e.key == argumentName)
                    ?.value;
            if (argumentValue == null) {
              continue;
            }

            gameArguments.add(
              argument.replaceFirst('\${$argumentName}', argumentValue),
            );
          } else {
            gameArguments.add(argument);
          }
        case EitherRight<String, MinecraftConditionalArg>():
          // Ignores all arguments with rules for now (e..g, QuickPlay, custom resolution)
          // to keep the launch minimal.
          continue;
      }
    }

    final unhandledJvmArguments = versionArguments.jvm;

    final clientJarDownloadUrl = versionDetails.downloads.client.url;

    final clientJarFile = appDataPaths.versionClientJarFile(versionId);

    if (!clientJarFile.existsSync()) {
      print('Downloading client JAR file...');
      await dio.downloadUri(
        Uri.parse(clientJarDownloadUrl),
        clientJarFile.path,
      );
    }

    classpath.add(clientJarFile.absolute.path);

    final libraries =
        versionDetails.libraries.where((library) {
          final rules = library.rules ?? [];
          if (rules.isEmpty) {
            return true;
          }
          final firstRule = rules.firstOrNull?.os;
          final targetOsName = firstRule?.name;
          // final targetOsVersion = firstRule?['version'] as String?;
          if (targetOsName == osName) {
            return true;
          }
          print(
            'Ignoring this library since it is not for this os: ${library.name}',
          );
          return false;
        }).toList();

    for (final libraryJson in libraries) {
      final artifact = libraryJson.downloads.artifact;
      final downloadUrl = artifact!.url;

      final libraryPath = artifact.path;
      final libraryFile = File(p.join(librariesDirPath, libraryPath));
      if (!libraryFile.existsSync()) {
        libraryFile.parent.createSync(recursive: true);
        print('Downloading library file `${libraryFile.path}...`');
        await dio.downloadUri(Uri.parse(downloadUrl), libraryFile.path);
      }
      classpath.add(libraryFile.absolute.path);
    }

    final loggingClientJson = versionDetails.logging.client;

    final logConfigFileDownloadUrl = loggingClientJson.file.url;
    final loggingFileId = loggingClientJson.file.id;

    final logConfigFile = File(
      p.join(assetsDirPath, 'log_configs', loggingFileId),
    );
    if (!logConfigFile.existsSync()) {
      logConfigFile.parent.createSync(recursive: true);

      print('Downloading log config file `$logConfigFileDownloadUrl`...');
      await dio.downloadUri(
        Uri.parse(logConfigFileDownloadUrl),
        logConfigFile.path,
      );
    }

    final jvmArguments = <String>[];

    final logConfigArgument = loggingClientJson.argument.replaceFirst(
      r'${path}',
      logConfigFile.absolute.path,
    );

    jvmArguments.add(logConfigArgument);

    for (final either in unhandledJvmArguments) {
      switch (either) {
        case EitherLeft<String, MinecraftConditionalArg>():
          assert(
            classpath.isNotEmpty,
            'The classpath should be builded and not empty',
          );
          final environmentSeparator = Platform.isWindows ? ';' : ':';
          final argumentValue = either.leftValue
              .replaceAll(r'${natives_directory}', nativesTempDir.absolute.path)
              .replaceAll(r'${launcher_name}', ProjectInfoConstants.displayName)
              .replaceAll(r'${launcher_version}', 'stable')
              .replaceAll(
                r'${classpath}',
                classpath.join(environmentSeparator),
              );
          jvmArguments.add(argumentValue);

        case EitherRight<String, MinecraftConditionalArg>():
          final arg = either.rightValue;
          final argValue = arg.value;
          final argumentValue = switch (argValue) {
            EitherLeft<String, List<String>>() => argValue.leftValue,
            EitherRight<String, List<String>>() => argValue.rightValue.first,
          };

          final os = arg.rules.first.os;
          final targetOsName = os?.name;
          if (targetOsName == osName) {
            jvmArguments.add(argumentValue);
          } else {
            // The only argument that uses this key is for x86 systems, and
            // this launcher doesn't support x86, ignoring this argument
            // since it's not useful.
            final targetOsArch = os?.arch;
            if (targetOsArch != null) {
              print(
                'Ignoring game argument `$argumentValue` since it is for os arch `$targetOsArch`',
              );
            } else {
              print(
                'Ignoring game argument `$argumentValue` as it is not for this os',
              );
            }
          }
      }
    }

    final assetIndexJson = versionDetails.assetIndex;
    final assetIndexJsonDownloadUrl = assetIndexJson.url;
    final assetIndexResponseData =
        (await dio.getUri<JsonMap>(
          Uri.parse(assetIndexJsonDownloadUrl),
        )).dataOrThrow;
    final assetIndexFile = File(
      p.join(assetsDirPath, 'indexes', '${assetIndexJson.id}.json'),
    );
    assetIndexFile.createSync(recursive: true);
    assetIndexFile.writeAsStringSync(jsonEncodePretty(assetIndexResponseData));

    final assetsPool = Pool(10, timeout: const Duration(seconds: 30));
    final assetFutures = <Future<void>>[];

    final assetObjects =
        ApiMinecraftAssetIndex.fromJson(assetIndexResponseData).objects;
    for (final assetObject in assetObjects.entries) {
      final assetHash = assetObject.value.hash;
      final firstTwo = assetHash.substring(0, 2);
      final downloadUri = Uri.https(
        StaticHosts.minecraftAssets,
        '$firstTwo/$assetHash',
      );

      final assetFile = File(
        p.join(assetsDirPath, 'objects', firstTwo, assetHash),
      );

      if (assetFile.existsSync()) {
        continue;
      }

      final future = assetsPool.withResource(() async {
        print('Downloading asset `${assetObject.key}`...');
        await dio.downloadUri(downloadUri, assetFile.path);
      });
      assetFutures.add(future);
    }

    await Future.wait(assetFutures);
    await assetsPool.close();

    final requiredJavaVersionComponent = versionDetails.javaVersion.component;

    final javaRuntimesResponseData =
        (await dio.getUri<JsonMap>(Uri.parse(javaRuntimesUrl))).dataOrThrow;

    final javaSystemRuntimeKey = switch (defaultTargetPlatform) {
      TargetPlatform.linux => () {
        assert(
          Platform.version.toLowerCase().contains('linux_x64'),
          'Only linux_x64 is supported',
        );
        return 'linux';
      }(),
      TargetPlatform.macOS => () {
        if (Platform.version.toLowerCase().contains('macos_arm64')) {
          return 'mac-os-arm64';
        }
        return 'mac-os';
      }(),
      TargetPlatform.windows => () {
        if (Platform.version.toLowerCase().contains('arm64')) {
          return 'windows-arm64';
        }
        return 'windows-x64';
      }(),
      _ => throw UnimplementedError('Unsupported OS: $defaultTargetPlatform'),
    };
    final runtimes = javaRuntimesResponseData[javaSystemRuntimeKey]! as JsonMap;
    // This will throw Bad state when there is no supported Java version on this machine,
    // for example, jre-legacy is required for Minecraft 1.16.5 but unsupported on macOS arm64.
    final runtimeDetails =
        (runtimes[requiredJavaVersionComponent]! as JsonList).firstOrNull
            as JsonMap? ??
        (throw Exception(
          'Unsupported java version component: $requiredJavaVersionComponent on this OS ($javaSystemRuntimeKey). Available components: $runtimes',
        ));
    final javaRuntimeManifestUrl =
        (runtimeDetails['manifest']! as JsonMap)['url']! as String;

    final javaRuntimeManifestResponseData =
        (await dio.getUri<JsonMap>(
          Uri.parse(javaRuntimeManifestUrl),
        )).dataOrThrow;
    final javaRuntimeFilesWithDirectories =
        javaRuntimeManifestResponseData['files']! as JsonMap;
    final javaRuntimeFiles = javaRuntimeFilesWithDirectories.entries.where(
      (e) => (e.value! as JsonMap)['type'] == 'file',
    );

    print(
      'Required Java runtime component: $requiredJavaVersionComponent, runtime key: $javaSystemRuntimeKey',
    );

    final javaRuntimePool = Pool(10, timeout: const Duration(seconds: 30));
    final javaRuntimeFutures = <Future<void>>[];

    final javaRuntimeHomeDirectory = Directory(
      p.join(javaRuntimesDirPath.path, requiredJavaVersionComponent),
    );

    if (!javaRuntimeHomeDirectory.existsSync()) {
      javaRuntimeHomeDirectory.createSync(recursive: true);
    }

    for (final javaRuntimeDetails in javaRuntimeFiles) {
      final runtimeValue = javaRuntimeDetails.value! as JsonMap;
      final filePath = javaRuntimeDetails.key;

      final runtimeFile = File(p.join(javaRuntimeHomeDirectory.path, filePath));

      if (runtimeFile.existsSync()) {
        continue;
      }
      final downloadUrl =
          ((runtimeValue['downloads']! as JsonMap)['raw']! as JsonMap)['url']!
              as String;

      final fileExecutable = FileExecutable();

      final future = javaRuntimePool.withResource(() async {
        print('Downloading runtime file `${javaRuntimeDetails.key}`...');
        await dio.downloadUri(Uri.parse(downloadUrl), runtimeFile.path);
        if (Platform.isLinux || Platform.isMacOS) {
          final executable = runtimeValue['executable']! as bool;
          if (executable) {
            print('Making file executable: ${['+x', runtimeFile.path]}');

            if (!fileExecutable.makeExecutable(runtimeFile.absolute.path)) {
              throw Exception(
                'Failed to make file executable: ${runtimeFile.absolute.path}',
              );
            }

            // Alternative solution that's less efficient:
            // // Improve: We could make this a single system call instead of many for each file.
            // final result = await Process.run('chmod', [
            //   '+x',
            //   runtimeFile.absolute.path,
            // ]);
            // if (result.exitCode != 0) {
            //   throw Exception(
            //     'Failed to make file executable: ${result.stderr}',
            //   );
            // }
          }
        }
      });
      javaRuntimeFutures.add(future);
    }

    await Future.wait(javaRuntimeFutures);
    await javaRuntimePool.close();

    final javaExecutableFile = File(switch (defaultTargetPlatform) {
      TargetPlatform.linux => p.join(
        javaRuntimeHomeDirectory.path,
        'bin',
        'java',
      ),
      TargetPlatform.macOS => p.join(
        javaRuntimeHomeDirectory.path,
        'jre.bundle',
        'Contents',
        'Home',
        'bin',
        'java',
      ),
      TargetPlatform.windows => p.join(
        javaRuntimeHomeDirectory.path,
        'bin',
        'javaw.exe',
      ),
      _ => throw UnsupportedError('Unsupported os: $defaultTargetPlatform'),
    });
    print('Java Path: ${javaExecutableFile.path}');

    print('log config argument: $logConfigArgument');
    print('game arguments: $gameArguments');
    print('jvm arguments: $jvmArguments');
    print('Client JAR: ${classpath.first}');

    final process = await Process.start(javaExecutableFile.absolute.path, [
      ...jvmArguments,
      mainClass,
      ...gameArguments,
    ], workingDirectory: gameDir.absolute.path);

    await process.stdout.transform(utf8.decoder).forEach(print);
    await process.stderr.transform(utf8.decoder).forEach(print);
    print('Process exit code: ${await process.exitCode}');
  }
}

// NOTE: The code of this file was implemented very quickly for prototyping,
// the code is far from being production ready and this will be replaced entirely
// later to implement it properly. The goal is to understand how the launch work
// to plan it properly.
