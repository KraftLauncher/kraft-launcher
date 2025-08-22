import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@immutable
class MinecraftRule extends Equatable {
  const MinecraftRule({
    required this.action,
    required this.features,
    required this.os,
  });

  final MinecraftRuleAction action;

  // Currently, this is used only for game arguments
  // on all launchers (including Minecraft Launcher).
  // See also: https://minecraft.wiki/w/Client.json
  final MinecraftRuleFeatures? features;

  // Currently, this is used only for libraries and JVM args
  // on all launchers (including Minecraft Launcher).
  // See also: https://minecraft.wiki/w/Client.json
  final MinecraftRuleOS? os;

  @override
  List<Object?> get props => [action, features, os];
}

enum MinecraftRuleAction { allow, disallow }

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

  final String? name;

  // Intended to be checked against `System.getProperty("os.version")` using Java.
  final String? version;
  final String? arch;

  @override
  List<Object?> get props => [name, version, arch];
}
