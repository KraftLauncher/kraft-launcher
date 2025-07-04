import 'package:kraft_launcher/launcher/data/minecraft_versions_api/models/asset_index/api_minecraft_asset_index.dart';
import 'package:kraft_launcher/launcher/logic/minecraft_versions/models/asset_index/minecraft_asset_index.dart';

extension ApiMinecraftAssetIndexMapper on ApiMinecraftAssetIndex {
  MinecraftAssetIndex toAppModel() => MinecraftAssetIndex(
    objects: objects.map(
      (key, value) => MapEntry(
        key,
        MinecraftAssetObject(hash: value.hash, size: value.size),
      ),
    ),
  );
}
