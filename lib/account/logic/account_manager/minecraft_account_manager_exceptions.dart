import 'package:meta/meta.dart';

import '../../data/microsoft_auth_api/microsoft_auth_exceptions.dart';
import '../../data/minecraft_api/minecraft_api_exceptions.dart';

@immutable
sealed class AccountManagerException implements Exception {
  const AccountManagerException(this.message);

  factory AccountManagerException.missingAuthCode() =>
      const MissingAuthCodeAccountManagerException();

  factory AccountManagerException.microsoftAuthApiException(
    MicrosoftAuthException authApiException,
  ) => MicrosoftApiAccountManagerException(authApiException);

  factory AccountManagerException.minecraftApiException(
    MinecraftApiException minecraftApiException,
  ) => MinecraftApiAccountManagerException(minecraftApiException);

  factory AccountManagerException.unknown(
    String message,
    StackTrace stackTrace,
  ) => UnknownAccountManagerException(message, stackTrace);

  final String message;

  @override
  String toString() => message;
}

final class MissingAuthCodeAccountManagerException
    extends AccountManagerException {
  const MissingAuthCodeAccountManagerException()
    : super(
        'The auth code query parameter should be passed to the redirect URL but was not found.',
      );
}

final class MicrosoftApiAccountManagerException
    extends AccountManagerException {
  MicrosoftApiAccountManagerException(this.authApiException)
    : super(authApiException.message);

  final MicrosoftAuthException authApiException;
}

final class MinecraftApiAccountManagerException
    extends AccountManagerException {
  MinecraftApiAccountManagerException(this.minecraftApiException)
    : super(minecraftApiException.message);

  final MinecraftApiException minecraftApiException;
}

final class UnknownAccountManagerException extends AccountManagerException {
  const UnknownAccountManagerException(super.message, this.stackTrace);

  final StackTrace stackTrace;
}
