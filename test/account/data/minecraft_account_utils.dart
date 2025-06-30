import 'package:kraft_launcher/account/logic/launcher_minecraft_account/minecraft_account.dart';
import 'package:kraft_launcher/account/logic/launcher_minecraft_account/minecraft_accounts.dart';

MinecraftAccounts createMinecraftAccounts({
  List<MinecraftAccount> list = const [],
  String? defaultAccountId,
}) => MinecraftAccounts(list: list, defaultAccountId: defaultAccountId);

MinecraftAccount createMinecraftAccount({
  String id = '',
  String username = '',
  AccountType accountType = AccountType.microsoft,
  MicrosoftAccountInfo? microsoftAccountInfo,
  bool isMicrosoftAccountInfoNull = false,
  List<MinecraftSkin> skins = const [],
  List<MinecraftCape> capes = const [],
  bool ownsMinecraftJava = false,
}) => MinecraftAccount(
  id: id,
  username: username,
  accountType: accountType,
  microsoftAccountInfo: () {
    return switch (accountType) {
      AccountType.microsoft =>
        isMicrosoftAccountInfoNull
            ? null
            : (microsoftAccountInfo ?? createMicrosoftAccountInfo()),
      AccountType.offline => null,
    };
  }(),
  skins: skins,
  capes: capes,
  ownsMinecraftJava: switch (accountType) {
    AccountType.microsoft => ownsMinecraftJava,
    AccountType.offline => null,
  },
);

MicrosoftAccountInfo createMicrosoftAccountInfo({
  ExpirableToken? microsoftRefreshToken,
  ExpirableToken? minecraftAccessToken,
  MicrosoftReauthRequiredReason? reauthRequiredReason,
}) => MicrosoftAccountInfo(
  microsoftRefreshToken: microsoftRefreshToken ?? createExpirableToken(),
  minecraftAccessToken: minecraftAccessToken ?? createExpirableToken(),
  reauthRequiredReason: reauthRequiredReason,
);

ExpirableToken createExpirableToken({
  String? value,
  DateTime? expiresAt,
  bool isValueNull = false,
}) => ExpirableToken(
  value: isValueNull ? null : (value ?? ''),
  expiresAt: expiresAt ?? DateTime(2099),
);

MinecraftSkin createMinecraftSkin({
  String id = '',
  MinecraftCosmeticState state = MinecraftCosmeticState.inactive,
  String url = '',
  String textureKey = '',
  MinecraftSkinVariant variant = MinecraftSkinVariant.classic,
}) => MinecraftSkin(
  id: id,
  state: state,
  url: url,
  textureKey: textureKey,
  variant: variant,
);

MinecraftCape createMinecraftCape({
  String id = '',
  MinecraftCosmeticState state = MinecraftCosmeticState.inactive,
  String url = '',
  String alias = '',
}) => MinecraftCape(id: id, state: state, url: url, alias: alias);
