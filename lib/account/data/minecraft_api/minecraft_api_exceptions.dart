import 'package:meta/meta.dart';

// TODO: We need proper naming convnetion for the exceptions before moving forward, refactor all exceptions to follow it.

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

  factory MinecraftApiException.accountNotFound() =>
      const AccountNotFoundMinecraftApiException();

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

final class AccountNotFoundMinecraftApiException extends MinecraftApiException {
  const AccountNotFoundMinecraftApiException()
    : super(
        'The Minecraft account was not found. Does the user have a valid Minecraft account?',
      );
}

final class InvalidSkinImageDataMinecraftApiException
    extends MinecraftApiException {
  const InvalidSkinImageDataMinecraftApiException()
    : super('The uploaded skin image data file is invalid.');
}
