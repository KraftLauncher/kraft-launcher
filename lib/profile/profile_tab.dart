// ignore_for_file: avoid_print, require_trailing_commas

// NOTE: The code of this file was implemented very quickly for prototyping,
// the code is far from being production ready and this will be replaced entirely
// later to implement it properly. The goal is to understand how the launch work
// to plan it properly.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:pool/pool.dart';

import '../account/data/minecraft_account.dart';
import '../account/logic/account_cubit.dart';
import '../common/constants/project_info_constants.dart';
import '../common/logic/app_data_paths.dart';
import '../common/logic/dio_client.dart';
import '../common/logic/json.dart';
import '../common/ui/utils/build_context_ext.dart';
import '../common/ui/utils/scaffold_messenger_ext.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  static const manifestUrl =
      'https://piston-meta.mojang.com/mc/game/version_manifest_v2.json';
  static const javaRuntimesUrl =
      'https://launchermeta.mojang.com/v1/products/java-runtime/2ec0cc96c44e5a76b9c8b7c39df7210883d12871/all.json';

  // Also see https://launchermeta.mojang.com/v1/products/java-runtime/2ec0cc96c44e5a76b9c8b7c39df7210883d12871/all.json
  // and https://gist.github.com/skyrising/95a8e6a7287634e097ecafa2f21c240f

  final _versionController = TextEditingController();
  var _isLoading = false;

  @override
  void initState() {
    super.initState();
    _versionController.text = '1.21.5';
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
    final mcDirPath = p.join(
      AppDataPaths.instance.workingDirectory.path,
      'minecraft',
    );
    print('MC Dir: ${File(mcDirPath).absolute.path}');
    final librariesDirPath = p.join(mcDirPath, 'libraries');
    final assetsDirPath = p.join(mcDirPath, 'assets');
    final javaRuntimesDirPath = Directory(p.join(mcDirPath, 'runtimes'));

    final gameDir = Directory(p.join(mcDirPath, 'game'));
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

    final dio = DioClient.instance;
    final response = await dio.getUri<JsonObject>(Uri.parse(manifestUrl));

    print('Fetching version manifest...');

    final responseData = response.dataOrThrow;
    final versions =
        (responseData['versions']! as List<dynamic>).cast<JsonObject>();
    final version = versions.firstWhere(
      (version) => version['id'] == _versionController.text,
    );
    final versionUrl = version['url']! as String;
    final versionId = version['id']! as String;
    final versionDetailsResponse = await dio.getUri<JsonObject>(
      Uri.parse(versionUrl),
    );

    print('Fetching version details...');

    final versionDetailsResponseData = versionDetailsResponse.dataOrThrow;
    final versionArguments =
        versionDetailsResponseData['arguments']! as JsonObject;

    final mainClass = versionDetailsResponseData['mainClass']! as String;

    final unhandledGameArguments = versionArguments['game']! as List<dynamic>;
    final gameArguments = <String>[];
    final classpath = <String>[];

    for (final argumentJson in unhandledGameArguments) {
      // Each item can be a Map or String
      if (argumentJson is String) {
        final argument = argumentJson;

        if (argument.startsWith(r'${') && argument.endsWith('}')) {
          final argumentName = argument
              .replaceFirst(r'${', '')
              .replaceAll('}', '');
          final map = <String, String?>{
            'auth_player_name': account.username,
            'version_name': versionId,
            'game_directory': gameDir.absolute.path,
            'assets_root': File(assetsDirPath).absolute.path,
            'assets_index_name':
                versionDetailsResponseData['assets']! as String,
            'auth_uuid': account.id,
            'auth_access_token':
                account.microsoftAccountInfo!.minecraftAccessToken.value,
            'clientid': 'null',
            'auth_xuid': '0',
            'user_type': 'msa',
            'version_type': versionDetailsResponseData['type']! as String,
          };
          final argumentValue =
              map.entries.firstWhereOrNull((e) => e.key == argumentName)?.value;
          if (argumentValue == null) {
            continue;
          }

          gameArguments.add(
            argument.replaceFirst('\${$argumentName}', argumentValue),
          );
        } else {
          gameArguments.add(argument);
        }
      } else if (argumentJson is JsonObject) {
        // Ignores all arguments with rules for now (e..g, QuickPlay, custom resolution)
        // to keep the launch minimal.
        continue;
      } else {
        throw UnimplementedError(
          'Unknown game argument type: ${argumentJson.runtimeType}',
        );
      }
    }
    final unhandledJvmArguments = versionArguments['jvm']! as List<dynamic>;

    final clientJarDownloadUrl =
        ((versionDetailsResponseData['downloads']! as JsonObject)['client']!
                as JsonObject)['url']!
            as String;

    final clientJarFile = File(
      p.join(mcDirPath, 'versions', versionId, '$versionId.jar'),
    );
    final clientJsonFile = File(
      p.join(mcDirPath, 'versions', versionId, '$versionId.json'),
    );
    if (!clientJarFile.existsSync()) {
      print('Downloading client JAR file...');
      await dio.downloadUri(
        Uri.parse(clientJarDownloadUrl),
        p.join(mcDirPath, 'versions', versionId, '$versionId.jar'),
      );
    }
    clientJsonFile.writeAsStringSync(
      jsonEncodePretty(versionDetailsResponseData),
    );
    classpath.add(clientJarFile.absolute.path);

    final libraries =
        (versionDetailsResponseData['libraries']! as List<dynamic>)
            .cast<JsonObject>()
            .where((jsonObject) {
              final rules =
                  (jsonObject['rules'] as List<dynamic>?)?.cast<JsonObject>() ??
                  [];
              if (rules.isEmpty) {
                return true;
              }
              final firstRule = rules.firstOrNull?['os'] as JsonObject?;
              final targetOsName = firstRule?['name'] as String?;
              // final targetOsVersion = firstRule?['version'] as String?;
              if (targetOsName == osName) {
                return true;
              }
              print(
                'Ignoring this library since it is not for this os: ${jsonObject['name']! as String}',
              );
              return false;
            })
            .toList();

    for (final libraryJson in libraries) {
      final artifact =
          (libraryJson['downloads']! as JsonObject)['artifact']! as JsonObject;
      final downloadUrl = artifact['url']! as String;

      final libraryPath = artifact['path']! as String;
      final libraryFile = File(p.join(librariesDirPath, libraryPath));
      if (!libraryFile.existsSync()) {
        libraryFile.parent.createSync(recursive: true);
        print('Downloading library file `${libraryFile.path}...`');
        await dio.downloadUri(Uri.parse(downloadUrl), libraryFile.path);
      }
      classpath.add(libraryFile.absolute.path);
    }

    final loggingClientJson =
        (versionDetailsResponseData['logging']! as JsonObject)['client']!
            as JsonObject;

    final logConfigFileDownloadUrl =
        (loggingClientJson['file']! as JsonObject)['url']! as String;
    final loggingFileId =
        (loggingClientJson['file']! as JsonObject)['id']! as String;

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

    final logConfigArgument = (loggingClientJson['argument']! as String)
        .replaceFirst(r'${path}', logConfigFile.absolute.path);

    jvmArguments.add(logConfigArgument);

    for (final argumentJson in unhandledJvmArguments) {
      if (argumentJson is JsonObject) {
        final argumentValue = () {
          final value = argumentJson['value']!;
          if (value is List) {
            return value.first as String;
          } else if (value is String) {
            return value;
          } else {
            throw UnimplementedError(
              'Unknown JVM value argument type: ${value.runtimeType}',
            );
          }
        }();
        final os =
            (argumentJson['rules']! as List<dynamic>)
                    .cast<JsonObject>()
                    .first['os']!
                as JsonObject;
        final targetOsName = os['name'] as String?;
        if (targetOsName == osName) {
          jvmArguments.add(argumentValue);
        } else {
          // The only argument that uses this key is for x86 systems, and
          // this launcher doesn't support x86, ignoring this argument
          // since it's not useful.
          final targetOsArch = os['arch'] as String?;
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
      } else if (argumentJson is String) {
        assert(
          classpath.isNotEmpty,
          'The classpath should be builded and not empty',
        );
        final environmentSeparator = Platform.isWindows ? ';' : ':';
        final argumentValue = argumentJson
            .replaceAll(r'${natives_directory}', nativesTempDir.absolute.path)
            .replaceAll(r'${launcher_name}', ProjectInfoConstants.displayName)
            .replaceAll(r'${launcher_version}', 'stable')
            .replaceAll(r'${classpath}', classpath.join(environmentSeparator));
        jvmArguments.add(argumentValue);
      } else {
        throw UnimplementedError(
          'Unknown jvm argument type: ${argumentJson.runtimeType}',
        );
      }
    }

    final assetIndexJson =
        versionDetailsResponseData['assetIndex']! as JsonObject;
    final assetIndexJsonDownloadUrl = assetIndexJson['url']! as String;
    final assetIndexResponseData =
        (await dio.getUri<JsonObject>(
          Uri.parse(assetIndexJsonDownloadUrl),
        )).dataOrThrow;
    final assetIndexFile = File(
      p.join(assetsDirPath, 'indexes', assetIndexJson['id']! as String),
    );
    assetIndexFile.createSync(recursive: true);
    assetIndexFile.writeAsStringSync(jsonEncodePretty(assetIndexResponseData));

    final assetsPool = Pool(10, timeout: const Duration(seconds: 30));
    final assetFutures = <Future<void>>[];

    final assetObjects = assetIndexResponseData['objects']! as JsonObject;
    for (final assetObject in assetObjects.entries) {
      final assetObjectValue = assetObject.value! as JsonObject;

      final assetHash = assetObjectValue['hash']! as String;
      final firstTwo = assetHash.substring(0, 2);
      final downloadUrl =
          'https://resources.download.minecraft.net/$firstTwo/$assetHash';

      final assetFile = File(
        p.join(assetsDirPath, 'objects', firstTwo, assetHash),
      );

      if (assetFile.existsSync()) {
        continue;
      }

      final future = assetsPool.withResource(() async {
        print('Downloading asset `${assetObject.key}`...');
        await dio.downloadUri(Uri.parse(downloadUrl), assetFile.path);
      });
      assetFutures.add(future);
    }

    await Future.wait(assetFutures);
    await assetsPool.close();

    final requiredJavaVersionComponent =
        (versionDetailsResponseData['javaVersion']! as JsonObject)['component']!
            as String;

    final javaRuntimesResponseData =
        (await dio.getUri<JsonObject>(Uri.parse(javaRuntimesUrl))).dataOrThrow;

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
    final runtimes =
        javaRuntimesResponseData[javaSystemRuntimeKey]! as JsonObject;
    final runtimeDetails =
        (runtimes[requiredJavaVersionComponent]! as List<dynamic>).first
            as JsonObject;
    final javaRuntimeManifestUrl =
        (runtimeDetails['manifest']! as JsonObject)['url']! as String;

    final javaRuntimeManifestResponseData =
        (await dio.getUri<JsonObject>(
          Uri.parse(javaRuntimeManifestUrl),
        )).dataOrThrow;
    final javaRuntimeFilesWithDirectories =
        javaRuntimeManifestResponseData['files']! as JsonObject;
    final javaRuntimeFiles = javaRuntimeFilesWithDirectories.entries.where(
      (e) => (e.value! as JsonObject)['type'] == 'file',
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
      final runtimeValue = javaRuntimeDetails.value! as JsonObject;
      final filePath = javaRuntimeDetails.key;

      final runtimeFile = File(p.join(javaRuntimeHomeDirectory.path, filePath));

      if (runtimeFile.existsSync()) {
        continue;
      }
      final downloadUrl =
          ((runtimeValue['downloads']! as JsonObject)['raw']!
                  as JsonObject)['url']!
              as String;

      final future = javaRuntimePool.withResource(() async {
        print('Downloading runtime file `${javaRuntimeDetails.key}`...');
        await dio.downloadUri(Uri.parse(downloadUrl), runtimeFile.path);
        if (Platform.isLinux || Platform.isMacOS) {
          final executable = runtimeValue['executable']! as bool;
          if (executable) {
            print('Making file executable: ${['+x', runtimeFile.path]}');
            final result = await Process.run('chmod', [
              '+x',
              runtimeFile.absolute.path,
            ]);
            if (result.exitCode != 0) {
              throw Exception(
                'Failed to make file executable: ${result.stderr}',
              );
            }
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
