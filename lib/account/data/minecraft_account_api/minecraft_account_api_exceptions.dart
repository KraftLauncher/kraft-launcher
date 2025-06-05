import 'package:meta/meta.dart';

@immutable
sealed class MinecraftAccountApiException implements Exception {
  const MinecraftAccountApiException(this.message);

  factory MinecraftAccountApiException.unknown(
    String message,
    StackTrace stackTrace,
  ) => MinecraftAccountUnknownException(message, stackTrace);

  factory MinecraftAccountApiException.tooManyRequests() =>
      const MinecraftAccountTooManyRequestsException();

  factory MinecraftAccountApiException.unauthorized() =>
      const MinecraftAccountUnauthorizedException();

  factory MinecraftAccountApiException.invalidSkinImageData() =>
      const MinecraftAccountInvalidSkinImageDataException();

  factory MinecraftAccountApiException.accountNotFound() =>
      const MinecraftAccountNotFoundException();

  final String message;

  @override
  String toString() => message;
}

final class MinecraftAccountUnknownException
    extends MinecraftAccountApiException {
  const MinecraftAccountUnknownException(super.message, this.stackTrace);

  final StackTrace stackTrace;
}

final class MinecraftAccountUnauthorizedException
    extends MinecraftAccountApiException {
  const MinecraftAccountUnauthorizedException()
    : super(
        'Unauthorized access, the Minecraft access token is probably either invalid or expired.',
      );
}

final class MinecraftAccountTooManyRequestsException
    extends MinecraftAccountApiException {
  const MinecraftAccountTooManyRequestsException()
    : super(
        'Request limit reached while communicating with Minecraft API services.',
      );
}

final class MinecraftAccountNotFoundException
    extends MinecraftAccountApiException {
  const MinecraftAccountNotFoundException()
    : super(
        'The Minecraft account was not found. Does the user have a valid Minecraft account?',
      );
}

final class MinecraftAccountInvalidSkinImageDataException
    extends MinecraftAccountApiException {
  const MinecraftAccountInvalidSkinImageDataException()
    : super('The uploaded skin image data file is invalid.');
}
