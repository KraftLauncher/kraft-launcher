import 'package:kraft_launcher/launcher/data/minecraft_versions_api/models/api_minecraft_version_type.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/models/version_manifest/api_minecraft_version_manifest.dart';
import 'package:kraft_launcher/launcher/logic/minecraft_versions/models/minecraft_version_type.dart';
import 'package:kraft_launcher/launcher/logic/minecraft_versions/models/version_manifest/minecraft_version_manifest.dart';

extension ApiMinecraftVersionManifestMapper on ApiMinecraftVersionManifest {
  MinecraftVersionManifest toApp() => MinecraftVersionManifest(
    latest: MinecraftLatestVersions(
      release: latest.release,
      snapshot: latest.snapshot,
    ),
    versions:
        versions
            .map(
              (version) => MinecraftManifestVersion(
                detailsUrl: version.url,
                id: version.id,
                sha1: version.sha1,
                supportsSafetyFeatures: version.complianceLevel == 1,
                releasedAt: version.releaseTime,
                updatedAt: version.time,
                type: switch (version.type) {
                  ApiMinecraftVersionType.release =>
                    MinecraftVersionType.release,
                  ApiMinecraftVersionType.snapshot =>
                    MinecraftVersionType.snapshot,
                  ApiMinecraftVersionType.oldAlpha =>
                    MinecraftVersionType.oldAlpha,
                  ApiMinecraftVersionType.oldBeta =>
                    MinecraftVersionType.oldBeta,
                },
              ),
            )
            .toList(),
  );
}
