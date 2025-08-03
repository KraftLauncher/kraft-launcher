import 'package:json_utils/json_utils.dart';
import 'package:meta/meta.dart';
import 'package:minecraft_services_client/src/models/profile/skin/enums/minecraft_cosmetic_state.dart';
import 'package:minecraft_services_client/src/models/profile/skin/enums/minecraft_skin_variant.dart';

@immutable
class MinecraftProfileSkin {
  const MinecraftProfileSkin({
    required this.id,
    required this.state,
    required this.url,
    required this.textureKey,
    required this.variant,
  });

  factory MinecraftProfileSkin.fromJson(JsonMap json) => MinecraftProfileSkin(
    id: json['id']! as String,
    state: MinecraftCosmeticState.fromJson(json['state']! as String),
    url: json['url']! as String,
    textureKey: json['textureKey']! as String,
    variant: MinecraftSkinVariant.fromJson(json['variant']! as String),
  );

  final String id;
  final MinecraftCosmeticState state;
  final String url;
  final String textureKey;
  final MinecraftSkinVariant variant;

  @override
  String toString() =>
      'MinecraftProfileSkin(id: $id, state: $state, url: $url, textureKey: $textureKey, variant: $variant)';

  @override
  int get hashCode => Object.hash(id, state, url, textureKey, variant);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is MinecraftProfileSkin &&
        other.id == id &&
        other.state == state &&
        other.url == url &&
        other.textureKey == textureKey &&
        other.variant == variant;
  }
}
