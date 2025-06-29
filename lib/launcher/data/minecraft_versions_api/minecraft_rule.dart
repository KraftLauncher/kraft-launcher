import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../../common/logic/json.dart';

@immutable
class MinecraftRule extends Equatable {
  const MinecraftRule({
    required this.action,
    required this.features,
    required this.os,
  });

  factory MinecraftRule.fromJson(JsonMap json) => MinecraftRule(
    action: MinecraftRuleAction.fromJson(json['action']! as String),
    features: () {
      final featuresMap = json['features'] as JsonMap?;
      if (featuresMap == null) {
        return null;
      }
      return MinecraftRuleFeatures.fromJson(featuresMap);
    }(),
    os: () {
      final osMap = json['os'] as JsonMap?;
      if (osMap == null) {
        return null;
      }
      return MinecraftRuleOS.fromJson(osMap);
    }(),
  );

  final MinecraftRuleAction action;

  // Currently, used only for game arguments.
  // See also: https://minecraft.wiki/w/Client.json
  final MinecraftRuleFeatures? features;

  // Currently, used only for libraries and JVM args.
  // See also: https://minecraft.wiki/w/Client.json
  final MinecraftRuleOS? os;

  @override
  List<Object?> get props => [action, features, os];
}

enum MinecraftRuleAction {
  allow,
  disallow;

  static MinecraftRuleAction fromJson(String json) => switch (json) {
    'allow' => allow,
    'disallow' => disallow,
    String() =>
      throw UnsupportedError(
        'Unknown Minecraft Rule action from the API: $json',
      ),
  };
}

@immutable
class MinecraftRuleFeatures extends Equatable {
  const MinecraftRuleFeatures({
    required this.isDemoUser,
    required this.hasCustomResolution,
    required this.hasQuickPlaysSupport,
    required this.isQuickPlaySinglePlayer,
    required this.isQuickPlayMultiplayer,
    required this.isQuickPlayRealms,
  });

  factory MinecraftRuleFeatures.fromJson(JsonMap json) => MinecraftRuleFeatures(
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
class MinecraftRuleOS extends Equatable {
  const MinecraftRuleOS({
    required this.name,
    required this.version,
    required this.arch,
  });

  factory MinecraftRuleOS.fromJson(JsonMap json) => MinecraftRuleOS(
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
