import 'package:meta/meta.dart';
import 'package:minecraft_services_repository/src/models/profile/skin/enums/minecraft_cosmetic_state.dart';

@immutable
class MinecraftProfileCape {
  const MinecraftProfileCape({
    required this.id,
    required this.state,
    required this.url,
    required this.alias,
  });

  final String id;
  final MinecraftCosmeticState state;
  final String url;
  final String alias;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is MinecraftProfileCape &&
        other.id == id &&
        other.state == state &&
        other.url == url &&
        other.alias == alias;
  }

  @override
  int get hashCode => Object.hash(id, state, url, alias);

  @override
  String toString() =>
      'MinecraftProfileCape(id: $id, state: $state, url: $url, alias: $alias)';
}
