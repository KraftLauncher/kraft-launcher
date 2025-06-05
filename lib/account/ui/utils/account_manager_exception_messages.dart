import '../../../common/generated/l10n/app_localizations.dart';
import '../../data/microsoft_auth_api/microsoft_auth_api_exceptions.dart';
import '../../data/minecraft_account/minecraft_account.dart';
import '../../data/minecraft_account_api/minecraft_account_api_exceptions.dart';
import '../../logic/account_manager/minecraft_account_manager_exceptions.dart';

extension AccountManagerExceptionMessages on AccountManagerException {
  // TODO: Need to review this function and it's usages, should we throw Exception for special
  //  errors that needs to be handled and use the special error in there or use getMessage instead
  //  but always ensure to use the message from here directly.
  String getMessage(AppLocalizations loc) {
    final exception = this;
    return switch (exception) {
      AccountManagerMissingMicrosoftAuthCodeException() =>
        loc.missingAuthCodeError,
      AccountManagerMicrosoftAuthApiException() => () {
        final microsoftApiException = exception.exception;
        return switch (microsoftApiException) {
          MicrosoftAuthUnknownException() => loc.unexpectedMicrosoftApiError(
            exception.message,
          ),
          MicrosoftAuthCodeExpiredException() => loc.expiredAuthCodeError,

          MicrosoftAuthXboxTokenMicrosoftAccessTokenExpiredException() =>
            loc.expiredMicrosoftAccessTokenError,

          MicrosoftAuthInvalidRefreshTokenException() =>
            throw StateError(
              'Expected $MicrosoftAuthInvalidRefreshTokenException to be transformed into $AccountManagerInvalidMicrosoftRefreshToken. $MicrosoftAuthInvalidRefreshTokenException should be caught and handled so this is likely a bug',
            ),
          MicrosoftAuthTooManyRequestsException() =>
            loc.microsoftRequestLimitError,
          MicrosoftAuthXstsErrorException() => switch (microsoftApiException
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
      AccountManagerMinecraftAccountApiException() => switch (exception
          .exception) {
        MinecraftAccountUnknownException() => loc.unexpectedMinecraftApiError(
          exception.message,
        ),
        MinecraftAccountUnauthorizedException() =>
          loc.unauthorizedMinecraftAccessError,
        MinecraftAccountTooManyRequestsException() =>
          loc.minecraftRequestLimitError,
        MinecraftAccountInvalidSkinImageDataException() =>
          loc.invalidMinecraftSkinFile,
        MinecraftAccountNotFoundException() =>
          loc.minecraftAccountNotFoundError,
      },
      AccountManagerUnknownException() => loc.unexpectedError(
        exception.message,
      ),
      AccountManagerMicrosoftAuthCodeRedirectException() => loc
          .authCodeLoginUnknownError(
            exception.error,
            exception.errorDescription,
          ),
      AccountManagerMicrosoftAuthCodeDeniedException() =>
        loc.loginAttemptRejected,
      AccountManagerMinecraftEntitlementAbsentException() =>
        loc.minecraftOwnershipRequiredError,
      AccountManagerMicrosoftReAuthRequiredException() => switch (exception
          .reason) {
        MicrosoftReauthRequiredReason.accessRevoked =>
          loc.reAuthRequiredDueToAccessRevoked,
        MicrosoftReauthRequiredReason.refreshTokenExpired => loc.sessionExpired,
        MicrosoftReauthRequiredReason.tokensMissingFromSecureStorage =>
          loc.reAuthRequiredDueToMissingSecureAccountData,
        MicrosoftReauthRequiredReason.tokensMissingFromFileStorage =>
          loc.reAuthRequiredDueToMissingAccountTokensFromFileStorage,
      },
      AccountManagerInvalidMicrosoftRefreshToken() =>
        loc.sessionExpiredOrAccessRevoked,
    };
  }
}
