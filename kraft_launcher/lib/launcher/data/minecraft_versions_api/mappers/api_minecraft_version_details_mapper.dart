import 'package:kraft_launcher/common/functional/either.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/mappers/api_minecraft_rule_mapper.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/mappers/api_minecraft_version_type_mapper.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/models/version_details/api_minecraft_version_args.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/models/version_details/api_minecraft_version_args.dart'
    as api_model
    show StringOrConditionalArg;
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/models/version_details/api_minecraft_version_details.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/models/version_details/api_minecraft_version_library.dart';
import 'package:kraft_launcher/launcher/logic/minecraft_versions/models/version_details/minecraft_java_version_info.dart';
import 'package:kraft_launcher/launcher/logic/minecraft_versions/models/version_details/minecraft_version_args.dart'
    hide StringOrConditionalArg;
import 'package:kraft_launcher/launcher/logic/minecraft_versions/models/version_details/minecraft_version_args.dart'
    as app_model
    show StringOrConditionalArg;
import 'package:kraft_launcher/launcher/logic/minecraft_versions/models/version_details/minecraft_version_asset_index_info.dart';
import 'package:kraft_launcher/launcher/logic/minecraft_versions/models/version_details/minecraft_version_details.dart';
import 'package:kraft_launcher/launcher/logic/minecraft_versions/models/version_details/minecraft_version_downloads.dart';
import 'package:kraft_launcher/launcher/logic/minecraft_versions/models/version_details/minecraft_version_library.dart';
import 'package:kraft_launcher/launcher/logic/minecraft_versions/models/version_details/minecraft_version_logging_config.dart';

extension ApiMinecraftVersionDetailsMapper on ApiMinecraftVersionDetails {
  MinecraftVersionDetails toApp() => MinecraftVersionDetails(
    assetsVersion: assets,
    id: id,
    legacyArguments: minecraftArguments,
    updatedAt: time,
    releasedAt: releaseTime,
    supportsSafetyFeatures: complianceLevel == 1,
    mainClass: mainClass,
    type: type.toApp(),
    javaVersion: MinecraftJavaVersionInfo(
      component: javaVersion.component,
      majorVersion: javaVersion.majorVersion,
    ),
    logging: MinecraftLoggingConfig(
      client: () {
        final client = logging.client;
        return MinecraftClientLogging(
          argument: client.argument,
          file: MinecraftClientLoggingFile(
            id: client.file.id,
            sha1: client.file.sha1,
            size: client.file.size,
            url: client.file.url,
          ),
          type: client.type,
        );
      }(),
    ),
    assetIndex: MinecraftVersionAssetIndexInfo(
      id: assetIndex.id,
      sha1: assetIndex.sha1,
      url: assetIndex.url,
      assetIndexFileSize: assetIndex.size,
      totalAssetsSize: assetIndex.totalSize,
    ),
    downloads: () {
      final downloads = this.downloads;
      final client = downloads.client;

      return MinecraftVersionDownloads(
        client: MinecraftVersionDownload(
          sha1: client.sha1,
          size: client.size,
          url: client.url,
        ),
      );
    }(),
    arguments: () {
      final arguments = this.arguments;
      if (arguments == null) {
        return null;
      }
      return MinecraftVersionArgs(
        game: arguments.game
            .map<app_model.StringOrConditionalArg>((either) => either.toApp())
            .toList(),
        jvm: arguments.jvm
            .map<app_model.StringOrConditionalArg>((either) => either.toApp())
            .toList(),
      );
    }(),
    libraries: libraries
        .map(
          (library) => MinecraftVersionLibrary(
            name: library.name,
            downloads: () {
              final downloads = library.downloads;
              final artifact = downloads.artifact;
              final classifiers = downloads.classifiers;

              MinecraftLibraryArtifact fromApiModel(
                ApiMinecraftLibraryArtifact artifact,
              ) => MinecraftLibraryArtifact(
                path: artifact.path,
                sha1: artifact.sha1,
                size: artifact.size,
                url: artifact.url,
              );
              return MinecraftLibraryDownloads(
                artifact: artifact != null ? fromApiModel(artifact) : null,
                classifiers: classifiers != null
                    ? (classifiers.map(
                        (key, value) => MapEntry(key, fromApiModel(value)),
                      ))
                    : null,
              );
            }(),
            natives: library.natives,
            rules: library.rules?.map((rule) => rule.toApp()).toList(),
            extract: () {
              final extract = library.extract;
              if (extract == null) {
                return null;
              }
              return MinecraftNativesExtractionRules(exclude: extract.exclude);
            }(),
          ),
        )
        .toList(),
  );
}

// Confusing name but it just maps [api_model.StringOrConditionalArg] to [app_model.StringOrConditionalArg].
extension _ApiStringOrConditionalArgMapper on api_model.StringOrConditionalArg {
  app_model.StringOrConditionalArg toApp() {
    final either = this;
    return switch (either) {
      EitherLeft<String, ApiMinecraftConditionalArg>() =>
        app_model.StringOrConditionalArg.left(either.leftValue),
      EitherRight<String, ApiMinecraftConditionalArg>() =>
        app_model.StringOrConditionalArg.right(
          MinecraftConditionalArg(
            rules: either.rightValue.rules.map((rule) => rule.toApp()).toList(),
            value: either.rightValue.value,
          ),
        ),
    };
  }
}
