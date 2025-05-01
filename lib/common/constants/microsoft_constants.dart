// ignore_for_file: do_not_use_environment

abstract final class MicrosoftConstants {
  // TODO: Replace loginClientId and loginRedirectPort with real values directly later
  // Register the app in Azure Portal with "Allow public client flows" enabled: https://portal.azure.com/
  // Add `offline_access` in API permissions and submit
  // a form for Minecraft API access: https://help.minecraft.net/hc/en-us/articles/16254801392141
  static const loginClientId = String.fromEnvironment(
    'MICROSOFT_LOGIN_CLIENT_ID',
    defaultValue: 'missing-microsoft-client-id',
  );
  static const loginRedirectPort = int.fromEnvironment(
    'MICROSOFT_LOGIN_REDIRECT_PORT',
    defaultValue: 0,
  );
  static const loginRedirectUrl = 'http://127.0.0.1:$loginRedirectPort';
  static const loginRedirectCodeQueryParamName = 'code';
  static const loginScopes = 'XboxLive.signin offline_access';

  // Device code flow
  static const microsoftDeviceCodeLink = 'https://www.microsoft.com/link';

  // TODO: We could also provide a direct link of this app for easier access (e.g., https://account.live.com/consent/Edit?client_id=xxxxxxxxxx)
  static const revokeAccessLink = 'https://www.microsoft.com/consent';
}
