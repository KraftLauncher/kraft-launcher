import 'package:meta/meta.dart';

@immutable
sealed class MicrosoftAuthApiException implements Exception {
  const MicrosoftAuthApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class UnknownException extends MicrosoftAuthApiException {
  const UnknownException(super.message, this.stackTrace);

  final StackTrace stackTrace;
}

// The device code could also expire but it's handled in a result class instead of an exception.

final class AuthCodeExpiredException extends MicrosoftAuthApiException {
  const AuthCodeExpiredException()
    : super(
        'This Microsoft auth code has been already expired and cannot be used to exchange for Microsoft OAuth access and refresh tokens.',
      );
}

final class InvalidRefreshTokenException extends MicrosoftAuthApiException {
  const InvalidRefreshTokenException()
    : super(
        'Microsoft OAuth Refresh token expired or access revoked. The user needs to log in again to reauthorize.',
      );
}

final class XboxTokenMicrosoftAccessTokenExpiredException
    extends MicrosoftAuthApiException {
  const XboxTokenMicrosoftAccessTokenExpiredException()
    : super(
        'Could not get the Xbox live token as the required input which is Microsoft OAuth access token is already expired',
      );
}

final class TooManyRequestsException extends MicrosoftAuthApiException {
  const TooManyRequestsException()
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
  // The account is under the age of 18, an adult must add the account to the family group.
  accountUnderAge(xErr: 2148916238),
  // This Xbox account is permanently banned for violating community standards.
  accountBanned(xErr: 2148916227),
  // This Microsoft account has not accepted Xbox's Terms of Service.
  termsNotAccepted(xErr: 2148916234);

  const XstsError({required this.xErr});

  final int xErr;
}

final class XstsErrorException extends MicrosoftAuthApiException {
  const XstsErrorException(
    super.message, {
    required this.xstsError,
    required this.xErr,
  });

  /// Null when the not provided in the response body by the API. The error is unknown.
  final int? xErr;

  /// Null when [xErr] is not handled or unknown.
  final XstsError? xstsError;
}
