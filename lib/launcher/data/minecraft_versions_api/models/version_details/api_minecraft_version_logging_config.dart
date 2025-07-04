import 'package:equatable/equatable.dart';
import 'package:kraft_launcher/common/logic/json.dart';
import 'package:meta/meta.dart';

@immutable
class ApiMinecraftLoggingConfig extends Equatable {
  const ApiMinecraftLoggingConfig({required this.client});

  factory ApiMinecraftLoggingConfig.fromJson(JsonMap json) =>
      ApiMinecraftLoggingConfig(
        client: ApiMinecraftClientLogging.fromJson(json['client']! as JsonMap),
      );

  final ApiMinecraftClientLogging client;

  @override
  List<Object?> get props => [client];
}

@immutable
class ApiMinecraftClientLogging extends Equatable {
  const ApiMinecraftClientLogging({
    required this.argument,
    required this.file,
    required this.type,
  });

  factory ApiMinecraftClientLogging.fromJson(JsonMap json) =>
      ApiMinecraftClientLogging(
        argument: json['argument']! as String,
        file: ApiMinecraftClientLoggingFile.fromJson(json['file']! as JsonMap),
        type: json['type']! as String,
      );

  final String argument;
  final ApiMinecraftClientLoggingFile file;
  final String type;

  @override
  List<Object?> get props => [argument, file, type];
}

@immutable
class ApiMinecraftClientLoggingFile extends Equatable {
  const ApiMinecraftClientLoggingFile({
    required this.id,
    required this.sha1,
    required this.size,
    required this.url,
  });

  factory ApiMinecraftClientLoggingFile.fromJson(JsonMap json) =>
      ApiMinecraftClientLoggingFile(
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
