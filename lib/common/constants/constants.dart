import 'package:kraft_launcher/common/constants/project_info_constants.dart';
import 'package:kraft_launcher/common/generated/pubspec.g.dart';

abstract final class Constants {
  // TODO: Once a bug template is created, make this link more specific
  static const reportBugLink =
      '${ProjectInfoConstants.githubRepoLink}/issues/new';
  static const askQuestionLink =
      '${ProjectInfoConstants.githubRepoLink}/discussions/new?category=q-a';
  static const appDisplayVersion =
      'v${Pubspec.version} (${Pubspec.versionBuildNumber})';
  static const licenseDisplayName = 'MIT';
}

abstract final class MinecraftConstants {
  static const buyMinecraftLink =
      'https://www.minecraft.net/store/minecraft-deluxe-collection-pc';
  static const redeemMinecraftLink = 'https://www.minecraft.net/redeem';
  static const changeMinecraftUsernameLink =
      'https://www.minecraft.net/msaprofile/mygames/editprofile';
  // TODO: Decide where to use this?
  static const minecraftProfile = 'https://www.minecraft.net/msaprofile';
}

abstract final class MicrosoftConstants {
  static const loginScopes = 'XboxLive.signin offline_access';
  static const createXboxAccountLink = 'https://www.xbox.com/live';

  // For device code flow
  static const microsoftDeviceCodeLink = 'https://www.microsoft.com/link';

  // For auth code flow
  static const loginRedirectUrl =
      'http://127.0.0.1:${ProjectInfoConstants.microsoftLoginRedirectPort}';

  static const loginRedirectAuthCodeQueryParamName = 'code';
  static const loginRedirectErrorQueryParamName = 'error';
  static const loginRedirectErrorDescriptionQueryParamName =
      'error_description';
  static const loginRedirectAccessDeniedErrorCode = 'access_denied';

  // Microsoft API doesn't provides the expiration date of refresh token,
  // it's 90 days per: https://learn.microsoft.com/en-us/entra/identity-platform/refresh-tokens#token-lifetime.
  // The app will always need to handle the case where it's expired or access is revoked when sending the request.
  static const refreshTokenExpiresInDays = 90;
}

abstract final class ApiHosts {
  static const pistonMetaMojang = 'piston-meta.mojang.com';
  static const minecraftServices = 'api.minecraftservices.com';
  static const microsoftLoginLive = 'login.live.com';
  static const loginMicrosoftOnline = 'login.microsoftonline.com';
  static const xboxLiveUserAuth = 'user.auth.xboxlive.com';
  static const xboxLiveXstsAuth = 'xsts.auth.xboxlive.com';
}

abstract final class StaticHosts {
  static const minecraftAssets = 'resources.download.minecraft.net';
}

abstract final class DbusConstants {
  static const linuxDBusSecretServiceName = 'org.freedesktop.secrets';
}
