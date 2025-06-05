/// @docImport '../../data/microsoft_auth_api/microsoft_auth_api.dart';
library;

import 'package:meta/meta.dart';

import '../../data/microsoft_auth_api/microsoft_auth_api_exceptions.dart';
import '../../data/minecraft_account/minecraft_account.dart';
import '../../data/minecraft_account_api/minecraft_account_api_exceptions.dart';
import 'minecraft_account_manager.dart';

@immutable
sealed class AccountManagerException implements Exception {
  const AccountManagerException(this.message);

  factory AccountManagerException.missingMicrosoftAuthCode() =>
      const AccountManagerMissingMicrosoftAuthCodeException();

  factory AccountManagerException.microsoftAuthCodeRedirect({
    required String error,
    required String errorDescription,
  }) => AccountManagerMicrosoftAuthCodeRedirectException(
    error: error,
    errorDescription: errorDescription,
  );

  factory AccountManagerException.microsoftAuthCodeDenied() =>
      const AccountManagerMicrosoftAuthCodeDeniedException();

  factory AccountManagerException.minecraftEntitlementAbsent() =>
      const AccountManagerMinecraftEntitlementAbsentException();

  factory AccountManagerException.microsoftReAuthRequired(
    MicrosoftReauthRequiredReason reason,
  ) => AccountManagerMicrosoftReAuthRequiredException(reason);

  factory AccountManagerException.invalidMicrosoftRefreshToken(
    MinecraftAccount updatedAccount,
  ) => AccountManagerInvalidMicrosoftRefreshToken(updatedAccount);

  factory AccountManagerException.microsoftAuthApiException(
    MicrosoftAuthApiException exception,
  ) => AccountManagerMicrosoftAuthApiException(exception);

  factory AccountManagerException.minecraftAccountApiException(
    MinecraftAccountApiException exception,
  ) => AccountManagerMinecraftAccountApiException(exception);

  factory AccountManagerException.unknown(
    String message,
    StackTrace stackTrace,
  ) => AccountManagerUnknownException(message, stackTrace);

  final String message;

  @override
  String toString() => message;
}

final class AccountManagerMissingMicrosoftAuthCodeException
    extends AccountManagerException {
  const AccountManagerMissingMicrosoftAuthCodeException()
    : super(
        'The Microsoft auth code query parameter should be passed to the redirect URL but was not found.',
      );
}

final class AccountManagerMicrosoftAuthCodeRedirectException
    extends AccountManagerException {
  const AccountManagerMicrosoftAuthCodeRedirectException({
    required this.error,
    required this.errorDescription,
  }) : super(
         'Microsoft redirected the result which is an unknown error while logging via auth code: "$error", description: "$errorDescription".',
       );

  final String error;
  final String errorDescription;
}

final class AccountManagerMicrosoftAuthCodeDeniedException
    extends AccountManagerException {
  const AccountManagerMicrosoftAuthCodeDeniedException()
    : super(
        'While logging with Microsoft via auth code, the user has denied the authorization request.',
      );
}

final class AccountManagerMinecraftEntitlementAbsentException
    extends AccountManagerException {
  const AccountManagerMinecraftEntitlementAbsentException()
    : super(
        'The user does not possess the required Minecraft Java Edition entitlement for this account.',
      );
}

final class AccountManagerMicrosoftReAuthRequiredException
    extends AccountManagerException {
  AccountManagerMicrosoftReAuthRequiredException(this.reason)
    : super('Microsoft Re-authentication is required. Reason: ${reason.name}');

  final MicrosoftReauthRequiredReason reason;
}

/// The exception [MicrosoftAuthInvalidRefreshTokenException] originates
/// from [MicrosoftAuthApi] and will be
/// caught in [MinecraftAccountManager] and transformed into this exception,
/// which includes the updated account that indicates it needs re-authentication.
/// and this transformation is specific to [MinecraftAccountManager].
final class AccountManagerInvalidMicrosoftRefreshToken
    extends AccountManagerException {
  AccountManagerInvalidMicrosoftRefreshToken(this.updatedAccount)
    : super(
        'Microsoft OAuth Refresh token expired or access revoked. The account ${updatedAccount.id} needs re-authentication.',
      );

  /// The updated account that indicates it needs re-authentication.
  final MinecraftAccount updatedAccount;
}

final class AccountManagerMicrosoftAuthApiException
    extends AccountManagerException {
  AccountManagerMicrosoftAuthApiException(this.exception)
    : super(exception.message);

  final MicrosoftAuthApiException exception;
}

final class AccountManagerMinecraftAccountApiException
    extends AccountManagerException {
  AccountManagerMinecraftAccountApiException(this.exception)
    : super(exception.message);

  final MinecraftAccountApiException exception;
}

final class AccountManagerUnknownException extends AccountManagerException {
  const AccountManagerUnknownException(super.message, this.stackTrace);

  final StackTrace stackTrace;
}
