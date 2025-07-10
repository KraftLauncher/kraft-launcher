import 'package:kraft_launcher/launcher/data/minecraft_versions_api/models/api_minecraft_version_type.dart';
import 'package:kraft_launcher/launcher/logic/minecraft_versions/models/minecraft_version_type.dart';

extension ApiMinecraftVersionTypeMapper on ApiMinecraftVersionType {
  MinecraftVersionType toApp() => switch (this) {
    ApiMinecraftVersionType.release => MinecraftVersionType.release,
    ApiMinecraftVersionType.snapshot => MinecraftVersionType.snapshot,
    ApiMinecraftVersionType.oldAlpha => MinecraftVersionType.oldAlpha,
    ApiMinecraftVersionType.oldBeta => MinecraftVersionType.oldBeta,
  };
}
