import 'package:meta/meta.dart';

@immutable
sealed class MinecraftApiException implements Exception {
  const MinecraftApiException(this.message);

  factory MinecraftApiException.unknown(
    String message,
    StackTrace stackTrace,
  ) => UnknownMinecraftApiException(message, stackTrace);

  factory MinecraftApiException.tooManyRequests() =>
      const TooManyRequestsMinecraftApiException();

  factory MinecraftApiException.unauthorized() =>
      const UnauthorizedMinecraftApiException();

  factory MinecraftApiException.invalidSkinImageData() =>
      const InvalidSkinImageDataMinecraftApiException();

  final String message;

  @override
  String toString() => message;
}

final class UnknownMinecraftApiException extends MinecraftApiException {
  const UnknownMinecraftApiException(super.message, this.stackTrace);

  final StackTrace stackTrace;
}

final class UnauthorizedMinecraftApiException extends MinecraftApiException {
  const UnauthorizedMinecraftApiException()
    : super(
        'Unauthorized access, the Minecraft access token is probably either invalid or expired.',
      );
}

final class TooManyRequestsMinecraftApiException extends MinecraftApiException {
  const TooManyRequestsMinecraftApiException()
    : super(
        'Request limit reached while communicating with Minecraft API services.',
      );
}

final class InvalidSkinImageDataMinecraftApiException
    extends MinecraftApiException {
  const InvalidSkinImageDataMinecraftApiException()
    : super('The uploaded skin image data file is invalid.');
}
