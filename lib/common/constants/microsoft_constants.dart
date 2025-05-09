// ignore_for_file: do_not_use_environment

abstract final class MicrosoftConstants {
  // TODO: We have sent a form requesting access to Minecraft APIs, and we're waiting for the response: https://forms.office.com/Pages/ResponsePage.aspx?id=v4j5cvGGr0GRqy180BHbR-ajEQ1td1ROpz00KtS8Gd5UNVpPTkVLNFVROVQxNkdRMEtXVjNQQjdXVC4u

  // Register the app in Azure Portal with "Allow public client flows" enabled: https://portal.azure.com/
  // Add `offline_access` in API permissions and submit
  // a form for Minecraft API access: https://help.minecraft.net/hc/en-us/articles/16254801392141
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

  // TODO: We could also provide a direct link of this app for easier access (e.g., https://account.live.com/consent/Edit?client_id=xxxxxxxxxx)
  static const revokeAccessLink = 'https://www.microsoft.com/consent';
  static const createXboxAccountLink = 'https://www.xbox.com/live';
}
