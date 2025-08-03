enum MinecraftSkinVariant {
  classic,
  slim;

  static MinecraftSkinVariant fromJson(String json) => switch (json) {
    'CLASSIC' => classic,
    'SLIM' => slim,
    String() => throw UnsupportedError(
      'Unknown Minecraft skin variant from the API: $json',
    ),
  };

  // The API response uses uppercase strings, though it's case-insensitive.
  // We keep this mapping explicit to avoid coupling to Dart enum names.
  String toJson() => switch (this) {
    MinecraftSkinVariant.classic => 'CLASSIC',
    MinecraftSkinVariant.slim => 'SLIM',
  };
}
