import '../../../common/generated/l10n/app_localizations.dart';
import '../../data/microsoft_auth_api/microsoft_auth_exceptions.dart';
import '../../data/minecraft_api/minecraft_api_exceptions.dart';
import '../../logic/account_manager/minecraft_account_manager_exceptions.dart';

extension AccountManagerExceptionMessages on AccountManagerException {
  String getMessage(AppLocalizations loc) {
    final exception = this;
    return switch (exception) {
      MicrosoftMissingAuthCodeAccountManagerException() =>
        loc.missingAuthCodeError,
      MicrosoftApiAccountManagerException() => () {
        final microsoftApiException = exception.authApiException;
        return switch (microsoftApiException) {
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
          XstsErrorMicrosoftAuthException() => switch (microsoftApiException
              .xstsError) {
            null =>
              microsoftApiException.xErr != null
                  ? loc.xstsUnknownErrorWithDetails(
                    microsoftApiException.xErr.toString(),
                    microsoftApiException.message,
                  )
                  : loc.xstsUnknownError,
            XstsError.accountCreationRequired =>
              loc.xstsAccountCreationRequiredError,
            XstsError.regionUnavailable => loc.xstsRegionNotSupportedError,
            XstsError.adultVerificationRequired =>
              loc.xstsAdultVerificationRequiredError,
            XstsError.ageVerificationRequired =>
              loc.xstsAgeVerificationRequiredError,
            XstsError.accountUnderAge =>
              loc.xstsRequiresAdultConsentRequiredError,
          },
        };
      }(),
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
        AccountNotFoundMinecraftApiException() =>
          loc.minecraftAccountNotFoundError,
      },
      UnknownAccountManagerException() => loc.unexpectedError(
        exception.message,
      ),
      MicrosoftAuthCodeRedirectAccountManagerException() => loc
          .authCodeLoginUnknownError(
            exception.error,
            exception.errorDescription,
          ),
      MicrosoftAuthCodeDeniedAccountManagerException() =>
        loc.loginAttemptRejected,
    };
  }
}
