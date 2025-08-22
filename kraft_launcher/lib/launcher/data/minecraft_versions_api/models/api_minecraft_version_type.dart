enum ApiMinecraftVersionType {
  release,
  snapshot,
  oldAlpha,
  oldBeta;

  static ApiMinecraftVersionType fromJson(String json) => switch (json) {
    'release' => release,
    'snapshot' => snapshot,
    'old_alpha' => oldAlpha,
    'old_beta' => oldBeta,
    String() => throw UnsupportedError(
      'Unknown Minecraft version type from the API: $json',
    ),
  };
}
