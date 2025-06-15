import 'package:meta/meta.dart';

@immutable
sealed class MicrosoftAuthCodeFlowException implements Exception {
  const MicrosoftAuthCodeFlowException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class AuthCodeMissingException extends MicrosoftAuthCodeFlowException {
  const AuthCodeMissingException()
    : super(
        'The Microsoft auth code query parameter should be passed to the redirect URL but was not found.',
      );
}

final class AuthCodeRedirectException extends MicrosoftAuthCodeFlowException {
  const AuthCodeRedirectException({
    required this.error,
    required this.errorDescription,
  }) : super(
         'Microsoft redirected the result which is an unknown error while logging via auth code: "$error", description: "$errorDescription".',
       );

  final String error;
  final String errorDescription;
}

final class AuthCodeDeniedException extends MicrosoftAuthCodeFlowException {
  const AuthCodeDeniedException()
    : super(
        'While logging with Microsoft via auth code, the user has denied the authorization request.',
      );
}
