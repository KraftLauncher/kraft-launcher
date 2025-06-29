enum MinecraftVersionType {
  release,
  snapshot,
  oldAlpha,
  oldBeta;

  static MinecraftVersionType fromJson(String json) => switch (json) {
    'release' => release,
    'snapshot' => snapshot,
    'old_alpha' => oldAlpha,
    'old_beta' => oldBeta,
    String() =>
      throw UnsupportedError(
        'Unknown Minecraft version type from the API: $json',
      ),
  };

  String toJson() => switch (this) {
    MinecraftVersionType.release => 'release',
    MinecraftVersionType.snapshot => 'snapshot',
    MinecraftVersionType.oldAlpha => 'old_alpha',
    MinecraftVersionType.oldBeta => 'old_beta',
  };
}
