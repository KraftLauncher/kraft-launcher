import 'package:meta/meta.dart';

@immutable
sealed class MinecraftAccountApiException implements Exception {
  const MinecraftAccountApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class UnknownException extends MinecraftAccountApiException {
  const UnknownException(super.message, this.stackTrace);

  final StackTrace stackTrace;
}

final class UnauthorizedException extends MinecraftAccountApiException {
  const UnauthorizedException()
    : super(
        'Unauthorized access, the Minecraft access token is probably either invalid or expired.',
      );
}

final class TooManyRequestsException extends MinecraftAccountApiException {
  const TooManyRequestsException()
    : super(
        'Request limit reached while communicating with Minecraft API services.',
      );
}

final class AccountNotFoundException extends MinecraftAccountApiException {
  const AccountNotFoundException()
    : super(
        'The Minecraft account was not found. Does the user have a valid Minecraft account?',
      );
}

final class InvalidSkinImageDataException extends MinecraftAccountApiException {
  const InvalidSkinImageDataException()
    : super('The uploaded skin image data file is invalid.');
}

final class ServiceUnavailableException extends MinecraftAccountApiException {
  const ServiceUnavailableException()
    : super(
        'Minecraft service is temporarily unavailable (503). Please try again later.',
      );
}
