import 'package:meta/meta.dart';

import '../../../common/constants/constants.dart';
import '../../data/microsoft_auth_api/microsoft_auth_api.dart';
import '../../data/microsoft_auth_api/microsoft_auth_exceptions.dart';
import '../../data/minecraft_account.dart';
import '../../data/minecraft_api/minecraft_api_exceptions.dart';
import 'minecraft_account_manager.dart';

@immutable
sealed class AccountManagerException implements Exception {
  const AccountManagerException(this.message);

  factory AccountManagerException.microsoftMissingAuthCode() =>
      const MicrosoftMissingAuthCodeAccountManagerException();

  factory AccountManagerException.microsoftAuthCodeRedirect({
    required String error,
    required String errorDescription,
  }) => MicrosoftAuthCodeRedirectAccountManagerException(
    error: error,
    errorDescription: errorDescription,
  );

  factory AccountManagerException.microsoftAuthCodeDenied() =>
      const MicrosoftAuthCodeDeniedAccountManagerException();

  factory AccountManagerException.minecraftEntitlementAbsent() =>
      const MinecraftEntitlementAbsentAccountManagerException();

  factory AccountManagerException.microsoftRefreshTokenExpired() =>
      const MicrosoftRefreshTokenExpiredAccountManagerException();

  factory AccountManagerException.microsoftExpiredOrUnauthorizedRefreshToken(
    MinecraftAccount updatedAccount,
  ) => MicrosoftExpiredOrUnauthorizedRefreshTokenAccountManagerException(
    updatedAccount,
  );

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

final class MicrosoftMissingAuthCodeAccountManagerException
    extends AccountManagerException {
  const MicrosoftMissingAuthCodeAccountManagerException()
    : super(
        'The Microsoft auth code query parameter should be passed to the redirect URL but was not found.',
      );
}

final class MicrosoftAuthCodeRedirectAccountManagerException
    extends AccountManagerException {
  const MicrosoftAuthCodeRedirectAccountManagerException({
    required this.error,
    required this.errorDescription,
  }) : super(
         'While logging via auth code, Microsoft redirected the result which is an unknown error: "$error", description: "$errorDescription".',
       );

  final String error;
  final String errorDescription;
}

final class MicrosoftAuthCodeDeniedAccountManagerException
    extends AccountManagerException {
  const MicrosoftAuthCodeDeniedAccountManagerException()
    : super(
        'While logging with Microsoft via auth code, the user has denied the authorization request.',
      );
}

final class MinecraftEntitlementAbsentAccountManagerException
    extends AccountManagerException {
  const MinecraftEntitlementAbsentAccountManagerException()
    : super(
        'The user does not possess the required Minecraft Java Edition entitlement for this account.',
      );
}

final class MicrosoftRefreshTokenExpiredAccountManagerException
    extends AccountManagerException {
  const MicrosoftRefreshTokenExpiredAccountManagerException()
    : super(
        'The Microsoft refresh token has expired: ${MicrosoftConstants.refreshTokenExpiresInDays} days have passed since it was issued.',
      );
}

/// The exception [ExpiredOrUnauthorizedRefreshTokenMicrosoftAuthException] will be
/// caught in [MinecraftAccountManager] and transformed into this exception,
/// which includes the updated account that indicates it needs re-authentication.
/// The exception [ExpiredOrUnauthorizedRefreshTokenMicrosoftAuthException] originates from [MicrosoftAuthApi],
/// and this transformation is specific to [MinecraftAccountManager].
final class MicrosoftExpiredOrUnauthorizedRefreshTokenAccountManagerException
    extends AccountManagerException {
  MicrosoftExpiredOrUnauthorizedRefreshTokenAccountManagerException(
    this.updatedAccount,
  ) : super(
        'Microsoft OAuth Refresh token expired or access revoked. The account ${updatedAccount.id} needs re-authentication.',
      );

  /// The updated account that indicates it needs re-authentication.
  final MinecraftAccount updatedAccount;
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
