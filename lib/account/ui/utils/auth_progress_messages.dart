import '../../../common/generated/l10n/app_localizations.dart';
import '../../logic/microsoft/auth_flows/auth_code/microsoft_auth_code_flow.dart';
import '../../logic/microsoft/auth_flows/device_code/microsoft_device_code_flow.dart';
import '../../logic/microsoft/minecraft/account_refresher/minecraft_account_refresher.dart';
import '../../logic/microsoft/minecraft/account_resolver/minecraft_account_resolver.dart';
import '../../logic/microsoft/minecraft/account_service/minecraft_full_auth_progress.dart';

extension AuthProgressMessagesExt on MinecraftFullAuthProgress? {
  String getMessage(AppLocalizations loc) {
    final fullProgress = this;
    final message = switch (fullProgress) {
      null =>
        throw StateError('The auth progress is unknown, this is likely a bug.'),
      MinecraftFullAuthCodeProgress() => switch (fullProgress.progress) {
        MicrosoftAuthCodeProgress.waitingForUserLogin =>
          loc.authProgressWaitingForUserLogin,
        MicrosoftAuthCodeProgress.exchangingAuthCode =>
          loc.authProgressExchangingAuthCode,
      },
      MinecraftFullDeviceCodeProgress() => switch (fullProgress.progress) {
        MicrosoftDeviceCodeProgress.waitingForUserLogin =>
          loc.authProgressWaitingForUserLogin,
        MicrosoftDeviceCodeProgress.exchangingDeviceCode =>
          loc.authProgressExchangingDeviceCode,
      },
      MinecraftFullResolveAccountProgress() => switch (fullProgress.progress) {
        ResolveMinecraftAccountProgress.requestingXboxToken =>
          loc.authProgressRequestingXboxLiveToken,
        ResolveMinecraftAccountProgress.requestingXstsToken =>
          loc.authProgressRequestingXstsToken,
        ResolveMinecraftAccountProgress.loggingIntoMinecraft =>
          loc.authProgressLoggingIntoMinecraft,
        ResolveMinecraftAccountProgress.checkingMinecraftJavaOwnership =>
          loc.authProgressCheckingMinecraftJavaOwnership,
        ResolveMinecraftAccountProgress.fetchingProfile =>
          loc.authProgressFetchingMinecraftProfile,
      },
      MinecraftFullRefreshAccountProgress() => switch (fullProgress.refresh) {
        RefreshMinecraftAccountProgress.refreshingMicrosoftTokens =>
          loc.authProgressRefreshingMicrosoftTokens,
      },
    };
    return message;
  }
}
