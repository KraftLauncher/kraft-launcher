import '../generated/pubspec.g.dart';
import 'constants.dart';

/// Constants that contain values specific to this project
/// and should always be updated when forking, especially [microsoftLoginClientId].
abstract final class ProjectInfoConstants {
  static const displayName = 'Kraft Launcher';
  static const userAgentAppName = 'KraftLauncher';
  static const website = 'https://kraftlauncher.org';
  static const contactEmail = 'kraftlauncher@gmail.com';

  static const githubRepoLink = Pubspec.repository;

  /// IMPORTANT: Forks must update the [microsoftLoginClientId] and [microsoftLoginRedirectPort] as follows:
  ///
  /// 1. Register a Microsoft Azure account at https://azure.microsoft.com/pricing/purchase-options/azure-account.
  /// 2. Login to https://portal.azure.com/ with the same account.
  /// 3. Click on the navigation menu and select `Microsoft Entra ID`.
  /// 4. Click `Add application registration` and enter a name for the application.
  /// 5. Choose the account type. To allow all users to login, select `Accounts in any organizational directory (Any Microsoft Entra ID tenant - Multitenant) and personal Microsoft accounts (e.g. Skype, Xbox)`.
  /// 6. Configure the Redirect URI: select `public client/native (mobile and desktop)` and set the redirect URI to `http://127.0.0.1:$loginRedirectPort`.
  ///    Ensure you use a unique port different from the [microsoftLoginRedirectPort], and update [microsoftLoginRedirectPort] with the new port.
  /// 7. Open the newly created app registration in Azure, and replace [microsoftLoginClientId] with the value from the `Application (client) ID`.
  /// 8. Click `Manage`, then `Authentication`, and enable `Allow public client flows` to allow the device code to work.
  /// 9. Optionally, refer to the doc comment for [microsoftRevokeAccessLink] to update the link to use the newly registered app.
  /// 10. Add `offline_access` under API permissions.
  /// 11. Finally, submit the form to request access to the Minecraft APIs: https://help.minecraft.net/hc/en-us/articles/16254801392141.
  ///
  /// See also:
  ///  * [MicrosoftConstants.loginRedirectUrl]
  ///  * [Microsoft authentication](https://minecraft.wiki/w/Microsoft_authentication)
  static const microsoftLoginClientId = 'ec68d4a9-72ca-404a-a19d-c34ddf1459a2';

  /// This is used to temporarily start a web server to handle the redirect when logging
  /// in via auth code flow. This is not used when logging via device code flow.
  ///
  /// IMPORTANT: Forks must update this port to a unique one to avoid conflicts between apps.
  ///
  /// See also: [MicrosoftConstants.loginRedirectUrl]
  static const microsoftLoginRedirectPort = 37665;

  /// A link that allows users to revoke the app's access to their account.
  ///
  /// The `client_id` is hardcoded and should match the same app as [microsoftLoginClientId].
  ///
  /// This should be updated when updating [microsoftLoginClientId].
  ///
  /// To update this link:
  /// 1. Update the [microsoftLoginClientId].
  /// 2. Login with any Microsoft Account using the [microsoftLoginClientId].
  /// 3. Visit https://www.microsoft.com/consent with the same account.
  /// 4. Open the registered app, copy the link in the browser.
  static const microsoftRevokeAccessLink =
      'https://account.live.com/consent/Edit?client_id=0000000049694D4F';
}
