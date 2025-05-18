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
  factory MicrosoftAuthException.xstsError(
    String message, {
    required XstsError? xstsError,
    required int? xErr,
  }) => XstsErrorMicrosoftAuthException(
    message,
    xstsError: xstsError,
    xErr: xErr,
  );

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

// See also:
//  * https://learn.microsoft.com/en-us/answers/questions/583869/what-kind-of-xerr-is-displayed-during-xsts-authent
//  * https://minecraft.wiki/w/Microsoft_authentication
enum XstsError {
  // Microsoft account does not have an Xbox account.
  accountCreationRequired(xErr: 2148916233),
  // Accounts from countries where XBox Live is not available or banned.
  regionUnavailable(xErr: 2148916235),
  // You must complete adult verification on the Xbox homepage. (South Korea)
  adultVerificationRequired(xErr: 2148916236),
  // Age verification must be completed on the Xbox homepage. (South Korea)
  ageVerificationRequired(xErr: 2148916237),
  // The account is under the age of 18, an adult must add the account to the family.
  accountUnderAge(xErr: 2148916238);

  const XstsError({required this.xErr});

  final int xErr;
}

final class XstsErrorMicrosoftAuthException extends MicrosoftAuthException {
  const XstsErrorMicrosoftAuthException(
    super.message, {
    required this.xstsError,
    required this.xErr,
  });

  /// Null when the not provided in the response body by the API. The error is unknown.
  final int? xErr;

  /// Null when [xErr] is not handled or unknown.
  final XstsError? xstsError;
}
