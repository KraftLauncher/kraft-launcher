import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@immutable
class MinecraftAssetIndex extends Equatable {
  const MinecraftAssetIndex({required this.objects});

  final Map<String, MinecraftAssetObject> objects;

  @override
  List<Object?> get props => [objects];
}

@immutable
class MinecraftAssetObject extends Equatable {
  const MinecraftAssetObject({required this.hash, required this.size});

  final String hash;
  final int size;

  @override
  List<Object?> get props => [hash, size];
}
