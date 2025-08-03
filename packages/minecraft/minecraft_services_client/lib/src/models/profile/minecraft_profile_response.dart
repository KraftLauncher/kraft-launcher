import 'package:json_utils/json_utils.dart';
import 'package:meta/meta.dart';
import 'package:minecraft_services_client/src/models/profile/skin/minecraft_profile_cape.dart';
import 'package:minecraft_services_client/src/models/profile/skin/minecraft_profile_skin.dart';
import 'package:minecraft_services_client/src/utils/list_equals.dart';

@immutable
class MinecraftProfileResponse {
  const MinecraftProfileResponse({
    required this.id,
    required this.name,
    required this.skins,
    required this.capes,
  });

  factory MinecraftProfileResponse.fromJson(JsonMap json) =>
      MinecraftProfileResponse(
        id: json['id']! as String,
        name: json['name']! as String,
        skins: (json['skins']! as JsonList)
            .cast<JsonMap>()
            .map((skinMap) => MinecraftProfileSkin.fromJson(skinMap))
            .toList(),
        capes: (json['capes']! as JsonList)
            .cast<JsonMap>()
            .map((capeMap) => MinecraftProfileCape.fromJson(capeMap))
            .toList(),
      );

  final String id;
  final String name;
  final List<MinecraftProfileSkin> skins;
  final List<MinecraftProfileCape> capes;

  @override
  String toString() =>
      'MinecraftProfileResponse(id: $id, name: $name, skins: $skins, capes: $capes)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is MinecraftProfileResponse &&
        other.id == id &&
        other.name == name &&
        listEquals(other.skins, skins) &&
        listEquals(other.capes, capes);
  }

  @override
  int get hashCode =>
      Object.hash(id, name, Object.hashAll(skins), Object.hashAll(capes));
}
