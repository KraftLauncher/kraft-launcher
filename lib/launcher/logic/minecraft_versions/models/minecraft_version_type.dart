enum MinecraftVersionType {
  release,
  snapshot,
  oldAlpha,
  oldBeta;

  /// Returns the representation used in Minecraft game launch arguments.
  String toLaunchArgument() => switch (this) {
    MinecraftVersionType.release => 'release',
    MinecraftVersionType.snapshot => 'snapshot',
    MinecraftVersionType.oldAlpha => 'old_alpha',
    MinecraftVersionType.oldBeta => 'old_beta',
  };
}
