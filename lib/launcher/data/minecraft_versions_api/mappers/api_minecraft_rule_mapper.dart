import 'package:kraft_launcher/launcher/data/minecraft_versions_api/models/api_minecraft_rule.dart';
import 'package:kraft_launcher/launcher/logic/minecraft_versions/models/minecraft_rule.dart';

extension ApiMinecraftRuleMapper on ApiMinecraftRule {
  MinecraftRule toApp() => MinecraftRule(
    action: action.toApp(),
    features: () {
      final features = this.features;
      if (features == null) {
        return null;
      }
      return MinecraftRuleFeatures(
        hasCustomResolution: features.hasCustomResolution,
        isDemoUser: features.isDemoUser,
        hasQuickPlaysSupport: features.hasQuickPlaysSupport,
        isQuickPlayMultiplayer: features.isQuickPlayMultiplayer,
        isQuickPlayRealms: features.isQuickPlayRealms,
        isQuickPlaySinglePlayer: features.isQuickPlaySinglePlayer,
      );
    }(),
    os: () {
      final os = this.os;
      if (os == null) {
        return null;
      }
      return MinecraftRuleOS(name: os.name, version: os.version, arch: os.arch);
    }(),
  );
}

extension ApiMinecraftRuleActionMapper on ApiMinecraftRuleAction {
  MinecraftRuleAction toApp() => switch (this) {
    ApiMinecraftRuleAction.allow => MinecraftRuleAction.allow,
    ApiMinecraftRuleAction.disallow => MinecraftRuleAction.disallow,
  };
}
