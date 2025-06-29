import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../../../common/logic/json.dart';

@immutable
class MinecraftVersionDownloads extends Equatable {
  const MinecraftVersionDownloads({
    required this.client,
    required this.clientMappings,
    required this.server,
    required this.serverMappings,
  });

  factory MinecraftVersionDownloads.fromJson(JsonMap json) =>
      MinecraftVersionDownloads(
        client: MinecraftVersionDownload.fromJson(json['client']! as JsonMap),
        clientMappings: () {
          final clientMappingsMap = json['client_mappings'] as JsonMap?;
          if (clientMappingsMap == null) {
            return null;
          }
          return MinecraftVersionDownload.fromJson(clientMappingsMap);
        }(),
        server: MinecraftVersionDownload.fromJson(json['server']! as JsonMap),
        serverMappings: () {
          final serverMappingsMap = json['server_mappings'] as JsonMap?;
          if (serverMappingsMap == null) {
            return null;
          }
          return MinecraftVersionDownload.fromJson(serverMappingsMap);
        }(),
      );

  final MinecraftVersionDownload client;
  final MinecraftVersionDownload? clientMappings;
  final MinecraftVersionDownload server;
  final MinecraftVersionDownload? serverMappings;
  // There is also windows_server but it has been removed in 16w05a.

  @override
  List<Object?> get props => [client, clientMappings, server, serverMappings];
}

@immutable
class MinecraftVersionDownload extends Equatable {
  const MinecraftVersionDownload({
    required this.sha1,
    required this.size,
    required this.url,
  });

  factory MinecraftVersionDownload.fromJson(JsonMap json) =>
      MinecraftVersionDownload(
        sha1: json['sha1']! as String,
        size: json['size']! as int,
        url: json['url']! as String,
      );

  final String sha1;
  final int size;
  final String url;
  @override
  List<Object?> get props => [sha1, size, url];
}
