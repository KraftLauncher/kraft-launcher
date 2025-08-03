enum MinecraftCosmeticState {
  active,
  inactive;

  static MinecraftCosmeticState fromJson(String json) => switch (json) {
    'ACTIVE' => active,
    'INACTIVE' => inactive,
    String() => throw UnsupportedError(
      'Unknown Minecraft cosmetic state from the API: $json',
    ),
  };
}
