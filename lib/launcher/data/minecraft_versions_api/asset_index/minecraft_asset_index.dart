import 'package:equatable/equatable.dart';
import 'package:kraft_launcher/common/logic/json.dart';
import 'package:meta/meta.dart';

@immutable
class MinecraftAssetIndex extends Equatable {
  const MinecraftAssetIndex({required this.objects});

  factory MinecraftAssetIndex.fromJson(JsonMap json) => MinecraftAssetIndex(
    objects: (json['objects']! as Map<String, dynamic>)
        .cast<String, JsonMap>()
        .map((k, v) => MapEntry(k, MinecraftAssetObject.fromJson(v))),
  );

  final Map<String, MinecraftAssetObject> objects;

  @override
  List<Object?> get props => [objects];
}

@immutable
class MinecraftAssetObject extends Equatable {
  const MinecraftAssetObject({required this.hash, required this.size});

  factory MinecraftAssetObject.fromJson(JsonMap json) => MinecraftAssetObject(
    hash: json['hash']! as String,
    size: json['size']! as int,
  );

  final String hash;
  final int size;

  @override
  List<Object?> get props => [hash, size];
}
