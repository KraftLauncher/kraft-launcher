/// @docImport '../../../../data/microsoft_auth_api/microsoft_auth_api.dart';
/// @docImport 'minecraft_account_refresher.dart';
library;

import 'package:meta/meta.dart';

import '../../../../data/microsoft_auth_api/microsoft_auth_api_exceptions.dart'
    as microsoft_auth_api_exceptions;
import '../../../launcher_minecraft_account/minecraft_account.dart';

@immutable
sealed class MinecraftAccountRefresherException implements Exception {
  const MinecraftAccountRefresherException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The exception [microsoft_auth_api_exceptions.InvalidRefreshTokenException] originates
/// from [MicrosoftAuthApi] and will be
/// caught in [MinecraftAccountRefresher] and transformed into this exception,
/// which includes the updated account that indicates it needs re-authentication.
/// and this transformation is specific to [MinecraftAccountRefresher].
final class InvalidMicrosoftRefreshTokenException
    extends MinecraftAccountRefresherException {
  InvalidMicrosoftRefreshTokenException(this.updatedAccount)
    : super(
        'Microsoft OAuth Refresh token expired or access revoked. The account ${updatedAccount.id} needs re-authentication.',
      );

  /// The updated account that indicates it needs re-authentication.
  final MinecraftAccount updatedAccount;
}

final class MicrosoftReAuthRequiredException
    extends MinecraftAccountRefresherException {
  MicrosoftReAuthRequiredException(this.reason)
    : super('Microsoft Re-authentication is required. Reason: ${reason.name}');

  final MicrosoftReauthRequiredReason reason;
}
