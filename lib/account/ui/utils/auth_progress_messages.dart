import 'package:kraft_launcher/account/logic/microsoft/minecraft/account_service/minecraft_auth_progress.dart';
import 'package:kraft_launcher/common/generated/l10n/app_localizations.dart';

extension AuthProgressMessagesExt on MinecraftAuthProgress? {
  String getMessage(AppLocalizations loc) {
    return switch (this) {
      null =>
        throw StateError('The auth progress is unknown, this is likely a bug.'),
      MinecraftAuthProgress.waitingForUserLogin =>
        loc.authProgressWaitingForUserLogin,
      MinecraftAuthProgress.exchangingAuthCode =>
        loc.authProgressExchangingAuthCode,
      MinecraftAuthProgress.requestingXboxToken =>
        loc.authProgressRequestingXboxLiveToken,
      MinecraftAuthProgress.requestingXstsToken =>
        loc.authProgressRequestingXstsToken,
      MinecraftAuthProgress.loggingIntoMinecraft =>
        loc.authProgressLoggingIntoMinecraft,
      MinecraftAuthProgress.checkingMinecraftJavaOwnership =>
        loc.authProgressCheckingMinecraftJavaOwnership,
      MinecraftAuthProgress.fetchingProfile =>
        loc.authProgressFetchingMinecraftProfile,
      MinecraftAuthProgress.refreshingMicrosoftTokens =>
        loc.authProgressRefreshingMicrosoftTokens,
    };
  }
}
