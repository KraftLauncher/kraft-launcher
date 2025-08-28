import 'package:collection_utils/collection_utils.dart';
import 'package:meta/meta.dart';
import 'package:minecraft_services_repository/src/models/profile/skin/minecraft_profile_cape.dart';
import 'package:minecraft_services_repository/src/models/profile/skin/minecraft_profile_skin.dart';

@immutable
class MinecraftProfileResponse {
  const MinecraftProfileResponse({
    required this.id,
    required this.name,
    required this.skins,
    required this.capes,
  });

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
