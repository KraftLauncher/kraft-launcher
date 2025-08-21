import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@immutable
class MinecraftVersionAssetIndexInfo extends Equatable {
  const MinecraftVersionAssetIndexInfo({
    required this.id,
    required this.sha1,
    required this.assetIndexFileSize,
    required this.totalAssetsSize,
    required this.url,
  });

  final String id;
  final String sha1;
  final int assetIndexFileSize;
  final int totalAssetsSize;
  final String url;

  @override
  List<Object?> get props => [
    id,
    sha1,
    assetIndexFileSize,
    totalAssetsSize,
    url,
  ];
}
