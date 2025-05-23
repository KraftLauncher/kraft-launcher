import '../../../common/generated/l10n/app_localizations.dart';
import '../../data/microsoft_auth_api/microsoft_auth_exceptions.dart';
import '../../data/minecraft_api/minecraft_api_exceptions.dart';
import '../../logic/account_manager/minecraft_account_manager_exceptions.dart';

extension AccountManagerExceptionMessages on AccountManagerException {
  // TODO: Need to review this function and it's usages, should we throw Exception for special
  //  errors that needs to be handled and use the special error in there or use getMessage instead
  //  but always ensure to use the message from here directly.
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
            throw Exception(
              'Expected $ExpiredOrUnauthorizedRefreshTokenMicrosoftAuthException to be transformed into $MicrosoftExpiredOrUnauthorizedRefreshTokenAccountManagerException. $ExpiredOrUnauthorizedRefreshTokenMicrosoftAuthException should be caught and handled so this is likely a bug',
            ),
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
            XstsError.accountBanned => loc.xstsAccountBannedError,
            XstsError.termsNotAccepted => loc.xstsTermsNotAcceptedError,
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
      MinecraftEntitlementAbsentAccountManagerException() =>
        loc.minecraftOwnershipRequiredError,
      MicrosoftRefreshTokenExpiredAccountManagerException() =>
        loc.sessionExpired,
      MicrosoftExpiredOrUnauthorizedRefreshTokenAccountManagerException() =>
        loc.sessionExpiredOrAccessRevoked,
    };
  }
}
