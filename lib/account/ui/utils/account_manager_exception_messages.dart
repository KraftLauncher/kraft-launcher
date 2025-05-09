import '../../../common/generated/l10n/app_localizations.dart';
import '../../data/microsoft_auth_api/microsoft_auth_exceptions.dart';
import '../../data/minecraft_api/minecraft_api_exceptions.dart';
import '../../logic/account_manager/minecraft_account_manager_exceptions.dart';

extension AccountManagerExceptionMessages on AccountManagerException {
  String getMessage(AppLocalizations loc) {
    final exception = this;
    return switch (exception) {
      MissingAuthCodeAccountManagerException() => loc.missingAuthCodeError,
      MicrosoftApiAccountManagerException() => switch (exception
          .authApiException) {
        UnknownMicrosoftAuthException() => loc.unexpectedMicrosoftApiError(
          exception.message,
        ),

        AuthCodeExpiredMicrosoftAuthException() => loc.expiredAuthCodeError,

        XboxTokenRequestFailedDueToExpiredAccessTokenMicrosoftAuthException() =>
          loc.expiredMicrosoftAccessTokenError,

        ExpiredOrUnauthorizedRefreshTokenMicrosoftAuthException() =>
          loc.sessionExpiredOrAccessRevoked,
        TooManyRequestsMicrosoftAuthException() =>
          loc.microsoftRequestLimitError,
      },
      MinecraftApiAccountManagerException() => switch (exception
          .minecraftApiException) {
        UnknownMinecraftApiException() => loc.unexpectedMinecraftApiError(
          exception.message,
        ),

        UnauthorizedMinecraftApiException() =>
          loc.unauthorizedMinecraftAccessError,
        TooManyRequestsMinecraftApiException() =>
          loc.minecraftRequestLimitError,
        InvalidSkinImageDataMinecraftApiException() =>
          loc.invalidMinecraftSkinFile,
      },
      UnknownAccountManagerException() => loc.unexpectedError(
        exception.message,
      ),
    };
  }
}
