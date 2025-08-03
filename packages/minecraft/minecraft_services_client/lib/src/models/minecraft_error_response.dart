import 'package:json_utils/json_utils.dart';
import 'package:meta/meta.dart';

@immutable
class MinecraftErrorResponse {
  const MinecraftErrorResponse({
    required this.path,
    required this.error,
    required this.errorMessage,
  });

  factory MinecraftErrorResponse.fromJson(JsonMap json) =>
      MinecraftErrorResponse(
        path: json['path'] as String?,
        error: json['error'] as String?,
        errorMessage: json['errorMessage'] as String?,
      );

  final String? path;
  final String? error;
  final String? errorMessage;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is MinecraftErrorResponse &&
        other.path == path &&
        other.error == error &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(path, error, errorMessage);

  @override
  String toString() =>
      'MinecraftErrorResponse(path: $path, error: $error, errorMessage: $errorMessage)';
}
