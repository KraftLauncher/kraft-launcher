import 'package:kraft_launcher/account/data/microsoft_auth_api/microsoft_auth_api_exceptions.dart'
    as microsoft_auth_api_exceptions;
import 'package:kraft_launcher/account/data/minecraft_account_api/minecraft_account_api_exceptions.dart'
    as minecraft_account_api_exceptions;
import 'package:kraft_launcher/account/data/redirect_http_server_handler/redirect_http_server_handler_failures.dart'
    as redirect_http_server_handler_failures;
import 'package:kraft_launcher/account/logic/launcher_minecraft_account/minecraft_account.dart';
import 'package:kraft_launcher/account/logic/microsoft/auth_flows/auth_code/microsoft_auth_code_flow_exceptions.dart'
    as microsoft_auth_code_flow_exceptions;
import 'package:kraft_launcher/account/logic/microsoft/minecraft/account_refresher/minecraft_account_refresher_exceptions.dart'
    as minecraft_account_refresher_exceptions;
import 'package:kraft_launcher/account/logic/microsoft/minecraft/account_resolver/minecraft_account_resolver_exceptions.dart'
    as minecraft_account_resolver_exceptions;
import 'package:kraft_launcher/account/logic/microsoft/minecraft/account_service/minecraft_account_service_exceptions.dart'
    as minecraft_account_service_exceptions;
import 'package:kraft_launcher/common/generated/l10n/app_localizations.dart';

// TODO: Rename this file (bad name)

extension AccountManagerExceptionMessages
    on minecraft_account_service_exceptions.MinecraftAccountServiceException {
  // TODO: Need to review this function and it's usages, should we throw Exception for special
  //  errors that needs to be handled and use the special error in there or use getMessage instead
  //  but always ensure to use the message from here directly.
  String getMessage(AppLocalizations loc) {
    return switch (this) {
      minecraft_account_service_exceptions.MicrosoftAuthCodeFlowException(
        :final exception,
      ) =>
        switch (exception) {
          microsoft_auth_code_flow_exceptions.AuthCodeMissingException() =>
            loc.missingAuthCodeError,
          microsoft_auth_code_flow_exceptions.AuthCodeRedirectException(
            :final error,
            :final errorDescription,
          ) =>
            loc.authCodeLoginUnknownError(error, errorDescription),
          microsoft_auth_code_flow_exceptions.AuthCodeDeniedException() =>
            loc.loginAttemptRejected,
          microsoft_auth_code_flow_exceptions.AuthCodeServerStartException(
            :final failure,
          ) =>
            switch (failure) {
              redirect_http_server_handler_failures.PortInUseFailure(
                :final port,
              ) =>
                loc.authCodeServerStartFailurePortInUse(port),
              redirect_http_server_handler_failures.PermissionDeniedFailure(
                :final details,
              ) =>
                loc.authCodeServerStartFailurePermissionDenied(details),
              redirect_http_server_handler_failures.UnknownFailure(
                :final message,
              ) =>
                loc.authCodeServerStartFailureUnknown(message),
            },
        },
      minecraft_account_service_exceptions.MinecraftAccountResolverException(
        :final exception,
      ) =>
        switch (exception) {
          minecraft_account_resolver_exceptions.MinecraftJavaEntitlementAbsentException() =>
            loc.minecraftOwnershipRequiredError,
        },
      minecraft_account_service_exceptions.MinecraftAccountRefresherException(
        :final exception,
      ) =>
        switch (exception) {
          minecraft_account_refresher_exceptions.InvalidMicrosoftRefreshTokenException() =>
            loc.sessionExpiredOrAccessRevoked,
          minecraft_account_refresher_exceptions.MicrosoftReAuthRequiredException() =>
            switch (exception.reason) {
              MicrosoftReauthRequiredReason.accessRevoked =>
                loc.reAuthRequiredDueToAccessRevoked,
              MicrosoftReauthRequiredReason.refreshTokenExpired =>
                loc.sessionExpired,
              MicrosoftReauthRequiredReason.tokensMissingFromSecureStorage =>
                loc.reAuthRequiredDueToMissingSecureAccountData,
              MicrosoftReauthRequiredReason.tokensMissingFromFileStorage =>
                loc.reAuthRequiredDueToMissingAccountTokensFromFileStorage,
            },
        },
      minecraft_account_service_exceptions.MicrosoftAuthApiException(
        :final exception,
      ) =>
        switch (exception) {
          microsoft_auth_api_exceptions.UnknownException() => loc
              .unexpectedMicrosoftApiError(exception.message),
          microsoft_auth_api_exceptions.AuthCodeExpiredException() =>
            loc.expiredAuthCodeError,

          microsoft_auth_api_exceptions.XboxTokenMicrosoftAccessTokenExpiredException() =>
            loc.expiredMicrosoftAccessTokenError,

          microsoft_auth_api_exceptions.InvalidRefreshTokenException() =>
            throw StateError(
              'Expected ${microsoft_auth_api_exceptions.InvalidRefreshTokenException} to be transformed into ${minecraft_account_refresher_exceptions.InvalidMicrosoftRefreshTokenException}. ${microsoft_auth_api_exceptions.InvalidRefreshTokenException} should be caught and handled so this is likely a bug',
            ),
          microsoft_auth_api_exceptions.TooManyRequestsException() =>
            loc.microsoftRequestLimitError,
          microsoft_auth_api_exceptions.XstsErrorException(:final xstsError) =>
            switch (xstsError) {
              null =>
                exception.xErr != null
                    ? loc.xstsUnknownErrorWithDetails(
                      exception.xErr.toString(),
                      exception.message,
                    )
                    : loc.xstsUnknownError,
              microsoft_auth_api_exceptions.XstsError.accountCreationRequired =>
                loc.xstsAccountCreationRequiredError,
              microsoft_auth_api_exceptions.XstsError.regionUnavailable =>
                loc.xstsRegionNotSupportedError,
              microsoft_auth_api_exceptions
                  .XstsError
                  .adultVerificationRequired =>
                loc.xstsAdultVerificationRequiredError,
              microsoft_auth_api_exceptions.XstsError.ageVerificationRequired =>
                loc.xstsAgeVerificationRequiredError,
              microsoft_auth_api_exceptions.XstsError.accountUnderAge =>
                loc.xstsRequiresAdultConsentRequiredError,
              microsoft_auth_api_exceptions.XstsError.accountBanned =>
                loc.xstsAccountBannedError,
              microsoft_auth_api_exceptions.XstsError.termsNotAccepted =>
                loc.xstsTermsNotAcceptedError,
            },
        },
      minecraft_account_service_exceptions.MinecraftAccountApiException(
        :final exception,
      ) =>
        switch (exception) {
          // TODO: unexpectedMinecraftApiError is used incorrectly here,
          //  same as unexpectedMicrosoftApiError, should be used
          //  only when the server respond with an unknown errror,
          //  not when Dio throws DioException
          minecraft_account_api_exceptions.UnknownException() => loc
              .unexpectedMinecraftApiError(exception.message),
          minecraft_account_api_exceptions.UnauthorizedException() =>
            loc.unauthorizedMinecraftAccessError,
          minecraft_account_api_exceptions.TooManyRequestsException() =>
            loc.minecraftRequestLimitError,
          minecraft_account_api_exceptions.AccountNotFoundException() =>
            loc.minecraftAccountNotFoundError,
          minecraft_account_api_exceptions.InvalidSkinImageDataException() =>
            loc.invalidMinecraftSkinFile,
          minecraft_account_api_exceptions.ServiceUnavailableException() =>
            loc.minecraftAccountApiUnavailable,
        },
    };
  }
}
