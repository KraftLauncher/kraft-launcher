import '../../../common/generated/l10n/app_localizations.dart';
import '../../logic/account_manager/minecraft_account_manager.dart';

extension AuthProgressMessagesExt on MicrosoftAuthProgress? {
  String getMessage(AppLocalizations loc) {
    final message = switch (this) {
      null => 'The auth progress is unknown, this is likely a bug.',
      MicrosoftAuthProgress.waitingForUserLogin =>
        loc.authProgressWaitingForUserLogin,
      MicrosoftAuthProgress.exchangingAuthCode =>
        loc.authProgressExchangingAuthCode,
      MicrosoftAuthProgress.requestingXboxToken =>
        loc.authProgressRequestingXboxLiveToken,
      MicrosoftAuthProgress.requestingXstsToken =>
        loc.authProgressRequestingXstsToken,
      MicrosoftAuthProgress.loggingIntoMinecraft =>
        loc.authProgressLoggingIntoMinecraft,
      MicrosoftAuthProgress.fetchingProfile =>
        loc.authProgressFetchingMinecraftProfile,

      MicrosoftAuthProgress.exchangingDeviceCode =>
        loc.authProgressExchangingDeviceCode,
      MicrosoftAuthProgress.refreshingMicrosoftTokens =>
        loc.authProgressRefreshingMicrosoftTokens,
      MicrosoftAuthProgress.checkingMinecraftJavaOwnership =>
        loc.authProgressCheckingMinecraftJavaOwnership,
    };
    return message;
  }
}
