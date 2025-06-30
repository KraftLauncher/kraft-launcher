import 'package:equatable/equatable.dart';
import 'package:kraft_launcher/common/logic/json.dart';
import 'package:meta/meta.dart';

@immutable
class MinecraftLoggingConfig extends Equatable {
  const MinecraftLoggingConfig({required this.client});

  factory MinecraftLoggingConfig.fromJson(JsonMap json) =>
      MinecraftLoggingConfig(
        client: MinecraftClientLogging.fromJson(json['client']! as JsonMap),
      );

  final MinecraftClientLogging client;

  @override
  List<Object?> get props => [client];
}

@immutable
class MinecraftClientLogging extends Equatable {
  const MinecraftClientLogging({
    required this.argument,
    required this.file,
    required this.type,
  });

  factory MinecraftClientLogging.fromJson(JsonMap json) =>
      MinecraftClientLogging(
        argument: json['argument']! as String,
        file: MinecraftClientLoggingFile.fromJson(json['file']! as JsonMap),
        type: json['type']! as String,
      );

  final String argument;
  final MinecraftClientLoggingFile file;
  final String type;

  @override
  List<Object?> get props => [argument, file, type];
}

@immutable
class MinecraftClientLoggingFile extends Equatable {
  const MinecraftClientLoggingFile({
    required this.id,
    required this.sha1,
    required this.size,
    required this.url,
  });

  factory MinecraftClientLoggingFile.fromJson(JsonMap json) =>
      MinecraftClientLoggingFile(
        id: json['id']! as String,
        sha1: json['sha1']! as String,
        size: json['size']! as int,
        url: json['url']! as String,
      );

  final String id;
  final String sha1;
  final int size;
  final String url;

  @override
  List<Object?> get props => [id, sha1, size, url];
}
