import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@immutable
class MinecraftLoggingConfig extends Equatable {
  const MinecraftLoggingConfig({required this.client});

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

  final String id;
  final String sha1;
  final int size;
  final String url;

  @override
  List<Object?> get props => [id, sha1, size, url];
}
