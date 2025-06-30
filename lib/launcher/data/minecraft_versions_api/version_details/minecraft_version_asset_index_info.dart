import 'package:equatable/equatable.dart';
import 'package:kraft_launcher/common/logic/json.dart';
import 'package:meta/meta.dart';

@immutable
class MinecraftVersionAssetIndexInfo extends Equatable {
  const MinecraftVersionAssetIndexInfo({
    required this.id,
    required this.sha1,
    required this.size,
    required this.totalSize,
    required this.url,
  });

  factory MinecraftVersionAssetIndexInfo.fromJson(JsonMap json) =>
      MinecraftVersionAssetIndexInfo(
        id: json['id']! as String,
        sha1: json['sha1']! as String,
        size: json['size']! as int,
        totalSize: json['totalSize']! as int,
        url: json['url']! as String,
      );

  final String id;
  final String sha1;
  final int size;
  final int totalSize;
  final String url;

  @override
  List<Object?> get props => [id, sha1, size, totalSize, url];
}
