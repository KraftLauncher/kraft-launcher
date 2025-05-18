import 'package:kraft_launcher/account/data/minecraft_account.dart';

MinecraftAccount createMinecraftAccount({
  String id = '',
  String username = '',
  AccountType accountType = AccountType.microsoft,
  MicrosoftAccountInfo? microsoftAccountInfo,
  bool isMicrosoftAccountInfoNull = false,
  List<MinecraftSkin> skins = const [],
  bool ownsMinecraftJava = false,
}) => MinecraftAccount(
  id: id,
  username: username,
  accountType: accountType,
  microsoftAccountInfo:
      isMicrosoftAccountInfoNull
          ? null
          : (microsoftAccountInfo ?? createMicrosoftAccountInfo()),
  skins: skins,
  ownsMinecraftJava: ownsMinecraftJava,
);

MicrosoftAccountInfo createMicrosoftAccountInfo({
  ExpirableToken? microsoftOAuthAccessToken,
  ExpirableToken? microsoftOAuthRefreshToken,
  ExpirableToken? minecraftAccessToken,
  bool needsReAuthentication = false,
}) => MicrosoftAccountInfo(
  microsoftOAuthAccessToken:
      microsoftOAuthAccessToken ?? createExpirableToken(),
  microsoftOAuthRefreshToken:
      microsoftOAuthRefreshToken ?? createExpirableToken(),
  minecraftAccessToken: minecraftAccessToken ?? createExpirableToken(),
  needsReAuthentication: needsReAuthentication,
);

ExpirableToken createExpirableToken({String? value, DateTime? expiresAt}) =>
    ExpirableToken(value: value ?? '', expiresAt: expiresAt ?? DateTime(2017));
