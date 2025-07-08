import 'package:equatable/equatable.dart';
import 'package:kraft_launcher/common/data/json.dart';
import 'package:meta/meta.dart';

@immutable
class ApiMinecraftRule extends Equatable {
  const ApiMinecraftRule({
    required this.action,
    required this.features,
    required this.os,
  });

  factory ApiMinecraftRule.fromJson(JsonMap json) => ApiMinecraftRule(
    action: ApiMinecraftRuleAction.fromJson(json['action']! as String),
    features: () {
      final featuresMap = json['features'] as JsonMap?;
      if (featuresMap == null) {
        return null;
      }
      return ApiMinecraftRuleFeatures.fromJson(featuresMap);
    }(),
    os: () {
      final osMap = json['os'] as JsonMap?;
      if (osMap == null) {
        return null;
      }
      return ApiMinecraftRuleOS.fromJson(osMap);
    }(),
  );

  final ApiMinecraftRuleAction action;

  // Currently, this is used only for game arguments
  // on all launchers (including Minecraft Launcher).
  // See also: https://minecraft.wiki/w/Client.json
  final ApiMinecraftRuleFeatures? features;

  // Currently, this is used only for libraries and JVM args
  // on all launchers (including Minecraft Launcher).
  // See also: https://minecraft.wiki/w/Client.json
  final ApiMinecraftRuleOS? os;

  @override
  List<Object?> get props => [action, features, os];
}

enum ApiMinecraftRuleAction {
  allow,
  disallow;

  static ApiMinecraftRuleAction fromJson(String json) => switch (json) {
    'allow' => allow,
    'disallow' => disallow,
    String() =>
      throw UnsupportedError(
        'Unknown Minecraft Rule action from the API: $json',
      ),
  };
}

@immutable
class ApiMinecraftRuleFeatures extends Equatable {
  const ApiMinecraftRuleFeatures({
    required this.isDemoUser,
    required this.hasCustomResolution,
    required this.hasQuickPlaysSupport,
    required this.isQuickPlaySinglePlayer,
    required this.isQuickPlayMultiplayer,
    required this.isQuickPlayRealms,
  });

  factory ApiMinecraftRuleFeatures.fromJson(JsonMap json) =>
      ApiMinecraftRuleFeatures(
        isDemoUser: json['is_demo_user'] as bool?,
        hasCustomResolution: json['has_custom_resolution'] as bool?,
        hasQuickPlaysSupport: json['has_quick_plays_support'] as bool?,
        isQuickPlaySinglePlayer: json['is_quick_play_singleplayer'] as bool?,
        isQuickPlayMultiplayer: json['is_quick_play_multiplayer'] as bool?,
        isQuickPlayRealms: json['is_quick_play_realms'] as bool?,
      );
  final bool? isDemoUser;
  final bool? hasCustomResolution;
  final bool? hasQuickPlaysSupport;
  final bool? isQuickPlaySinglePlayer;
  final bool? isQuickPlayMultiplayer;
  final bool? isQuickPlayRealms;

  @override
  List<Object?> get props => [
    isDemoUser,
    hasCustomResolution,
    hasQuickPlaysSupport,
    isQuickPlaySinglePlayer,
    isQuickPlayMultiplayer,
    isQuickPlayRealms,
  ];
}

@immutable
class ApiMinecraftRuleOS extends Equatable {
  const ApiMinecraftRuleOS({
    required this.name,
    required this.version,
    required this.arch,
  });

  factory ApiMinecraftRuleOS.fromJson(JsonMap json) => ApiMinecraftRuleOS(
    name: json['name'] as String?,
    version: json['version'] as String?,
    arch: json['arch'] as String?,
  );

  final String? name;

  // Intended to be checked against `System.getProperty("os.version")` using Java.
  final String? version;
  final String? arch;

  @override
  List<Object?> get props => [name, version, arch];
}
