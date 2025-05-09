// ignore_for_file: do_not_use_environment

// TODO: Move values specific to the project to ProjectInfoConstants?
abstract final class MicrosoftConstants {
  // TODO: We have sent a form requesting access to Minecraft APIs, and we're waiting for the response: https://forms.office.com/Pages/ResponsePage.aspx?id=v4j5cvGGr0GRqy180BHbR-ajEQ1td1ROpz00KtS8Gd5UNVpPTkVLNFVROVQxNkdRMEtXVjNQQjdXVC4u

  /// Forks must update the [loginClientId] and [loginRedirectPort] as follows:
  ///
  /// 1. Register a Microsoft Azure account at https://azure.microsoft.com/pricing/purchase-options/azure-account.
  /// 2. Login to https://portal.azure.com/ with the same account.
  /// 3. Click on the navigation menu and select `Microsoft Entra ID`.
  /// 4. Click `Add application registration` and enter a name for the application.
  /// 5. Choose the account type. To allow all users to login, select `Accounts in any organizational directory (Any Microsoft Entra ID tenant - Multitenant) and personal Microsoft accounts (e.g. Skype, Xbox)`.
  /// 6. Configure the Redirect URI: select `public client/native (mobile and desktop)` and set the redirect URI to `http://127.0.0.1:$loginRedirectPort`.
  ///    Ensure you use a unique port different from the [loginRedirectPort], and update [loginRedirectPort] with the new port.
  /// 7. Open the newly created app registration in Azure, and replace [loginClientId] with the value from the `Application (client) ID`.
  /// 8. Click `Manage`, then `Authentication`, and enable `Allow public client flows` to allow the device code to work.
  /// 9. Optionally, refer to the doc comment for [revokeAccessLink] to update the link to use the newly registered app.
  /// 10. Add `offline_access` under API permissions.
  /// 11. Finally, submit the form to request access to the Minecraft APIs: https://help.minecraft.net/hc/en-us/articles/16254801392141
  static const loginClientId = String.fromEnvironment(
    'MICROSOFT_LOGIN_CLIENT_ID',
    defaultValue: 'ec68d4a9-72ca-404a-a19d-c34ddf1459a2',
  );
  static const loginRedirectPort = int.fromEnvironment(
    'MICROSOFT_LOGIN_REDIRECT_PORT',
    defaultValue: 37665,
  );
  static const loginRedirectUrl = 'http://127.0.0.1:$loginRedirectPort';
  static const loginRedirectCodeQueryParamName = 'code';
  static const loginScopes = 'XboxLive.signin offline_access';

  // Device code flow
  static const microsoftDeviceCodeLink = 'https://www.microsoft.com/link';

  /// The `client_id` is hardcoded and should match the same app as [loginClientId].
  ///
  /// This should be updated when updating [loginClientId].
  ///
  /// To update this link:
  /// 1. Update the [loginClientId].
  /// 2. Login with any Microsoft Account using the [loginClientId].
  /// 3. Visit https://www.microsoft.com/consent
  /// 4. Open the registered app, copy the link in the browser.
  static const revokeAccessLink =
      'https://account.live.com/consent/Edit?client_id=0000000049694D4F';
  static const createXboxAccountLink = 'https://www.xbox.com/live';
}
