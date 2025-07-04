import 'package:equatable/equatable.dart';
import 'package:kraft_launcher/common/logic/json.dart';
import 'package:meta/meta.dart';

@immutable
class ApiMinecraftAssetIndex extends Equatable {
  const ApiMinecraftAssetIndex({required this.objects});

  factory ApiMinecraftAssetIndex.fromJson(JsonMap json) =>
      ApiMinecraftAssetIndex(
        objects: (json['objects']! as Map<String, dynamic>)
            .cast<String, JsonMap>()
            .map((k, v) => MapEntry(k, ApiMinecraftAssetObject.fromJson(v))),
      );

  final Map<String, ApiMinecraftAssetObject> objects;

  @override
  List<Object?> get props => [objects];
}

@immutable
class ApiMinecraftAssetObject extends Equatable {
  const ApiMinecraftAssetObject({required this.hash, required this.size});

  factory ApiMinecraftAssetObject.fromJson(JsonMap json) =>
      ApiMinecraftAssetObject(
        hash: json['hash']! as String,
        size: json['size']! as int,
      );

  final String hash;
  final int size;

  @override
  List<Object?> get props => [hash, size];
}
