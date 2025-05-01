import 'package:meta/meta.dart';

@immutable
sealed class MicrosoftAuthException implements Exception {
  const MicrosoftAuthException(this.message);

  factory MicrosoftAuthException.unknown(
    String message,
    StackTrace stackTrace,
  ) => UnknownMicrosoftAuthException(message, stackTrace);
  factory MicrosoftAuthException.authCodeExpired() =>
      const AuthCodeExpiredMicrosoftAuthException();
  factory MicrosoftAuthException.expiredOrUnauthorizedMicrosoftRefreshToken() =>
      const ExpiredOrUnauthorizedRefreshTokenMicrosoftAuthException();
  factory MicrosoftAuthException.xboxTokenRequestFailedDueToExpiredAccessToken() =>
      const XboxTokenRequestFailedDueToExpiredAccessTokenMicrosoftAuthException();

  factory MicrosoftAuthException.tooManyRequests() =>
      const TooManyRequestsMicrosoftAuthException();

  final String message;

  @override
  String toString() => message;
}

final class UnknownMicrosoftAuthException extends MicrosoftAuthException {
  const UnknownMicrosoftAuthException(super.message, this.stackTrace);

  final StackTrace stackTrace;
}

final class AuthCodeExpiredMicrosoftAuthException
    extends MicrosoftAuthException {
  const AuthCodeExpiredMicrosoftAuthException()
    : super(
        'This auth code has been already expired and cannot be used to exchange for Microsoft OAuth access and refresh tokens.',
      );
}

// The device code could also expire but it's handled in a result class instead of exception.

final class ExpiredOrUnauthorizedRefreshTokenMicrosoftAuthException
    extends MicrosoftAuthException {
  const ExpiredOrUnauthorizedRefreshTokenMicrosoftAuthException()
    : super(
        'Microsoft OAuth Refresh token expired or access revoked. The user needs to log in again to reauthorize.',
      );
}

final class XboxTokenRequestFailedDueToExpiredAccessTokenMicrosoftAuthException
    extends MicrosoftAuthException {
  const XboxTokenRequestFailedDueToExpiredAccessTokenMicrosoftAuthException()
    : super(
        'Could not get the Xbox live token as the required input which is Microsoft OAuth access token is already expired',
      );
}

final class TooManyRequestsMicrosoftAuthException
    extends MicrosoftAuthException {
  const TooManyRequestsMicrosoftAuthException()
    : super(
        'Request limit reached while communicating with Microsoft authentication servers.',
      );
}
