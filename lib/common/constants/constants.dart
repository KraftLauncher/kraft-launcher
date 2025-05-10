import '../generated/pubspec.g.dart';
import 'project_info_constants.dart';

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
  // TODO: This is not used yet.
  static const buyMinecraftLink =
      'https://www.minecraft.net/store/minecraft-deluxe-collection-pc';
  static const changeMinecraftUsernameLink =
      'https://www.minecraft.net/msaprofile/mygames/editprofile';
  // TODO: Decide where to use this?
  static const minecraftProfile = 'https://www.minecraft.net/msaprofile';
}

abstract final class MicrosoftConstants {
  // Device code flow
  static const microsoftDeviceCodeLink = 'https://www.microsoft.com/link';

  static const createXboxAccountLink = 'https://www.xbox.com/live';

  static const loginRedirectCodeQueryParamName = 'code';
  static const loginScopes = 'XboxLive.signin offline_access';

  static const loginRedirectUrl =
      'http://127.0.0.1:${ProjectInfoConstants.microsoftLoginRedirectPort}';
}
