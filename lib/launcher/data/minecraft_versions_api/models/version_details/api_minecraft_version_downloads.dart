import 'package:equatable/equatable.dart';
import 'package:kraft_launcher/common/logic/json.dart';
import 'package:meta/meta.dart';

@immutable
class ApiMinecraftVersionDownloads extends Equatable {
  const ApiMinecraftVersionDownloads({
    required this.client,
    required this.clientMappings,
    required this.server,
    required this.serverMappings,
  });

  factory ApiMinecraftVersionDownloads.fromJson(
    JsonMap json,
  ) => ApiMinecraftVersionDownloads(
    client: ApiMinecraftVersionDownload.fromJson(json['client']! as JsonMap),
    clientMappings: () {
      final clientMappingsMap = json['client_mappings'] as JsonMap?;
      if (clientMappingsMap == null) {
        return null;
      }
      return ApiMinecraftVersionDownload.fromJson(clientMappingsMap);
    }(),
    server: ApiMinecraftVersionDownload.fromJson(json['server']! as JsonMap),
    serverMappings: () {
      final serverMappingsMap = json['server_mappings'] as JsonMap?;
      if (serverMappingsMap == null) {
        return null;
      }
      return ApiMinecraftVersionDownload.fromJson(serverMappingsMap);
    }(),
  );

  final ApiMinecraftVersionDownload client;
  final ApiMinecraftVersionDownload? clientMappings;
  final ApiMinecraftVersionDownload server;
  final ApiMinecraftVersionDownload? serverMappings;
  // There is also windows_server but it has been removed in 16w05a.

  @override
  List<Object?> get props => [client, clientMappings, server, serverMappings];
}

@immutable
class ApiMinecraftVersionDownload extends Equatable {
  const ApiMinecraftVersionDownload({
    required this.sha1,
    required this.size,
    required this.url,
  });

  factory ApiMinecraftVersionDownload.fromJson(JsonMap json) =>
      ApiMinecraftVersionDownload(
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
