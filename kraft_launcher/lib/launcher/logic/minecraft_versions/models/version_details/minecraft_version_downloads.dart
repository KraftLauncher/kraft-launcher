import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@immutable
class MinecraftVersionDownloads extends Equatable {
  const MinecraftVersionDownloads({required this.client});

  final MinecraftVersionDownload client;

  @override
  List<Object?> get props => [client];
}

@immutable
class MinecraftVersionDownload extends Equatable {
  const MinecraftVersionDownload({
    required this.sha1,
    required this.size,
    required this.url,
  });

  final String sha1;
  final int size;
  final String url;

  @override
  List<Object?> get props => [sha1, size, url];
}
