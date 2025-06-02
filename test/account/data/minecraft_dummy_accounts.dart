import 'package:kraft_launcher/account/data/minecraft_account/minecraft_account.dart';
import 'package:kraft_launcher/account/data/minecraft_account/minecraft_accounts.dart';

import 'minecraft_account_utils.dart';

abstract final class MinecraftDummyAccounts {
  static const _defaultAccountId = 'uuid-microsoft-1';

  // The account to remove or update
  static const targetAccountId = 'uuid-microsoft-2';

  static final _list = List<MinecraftAccount>.unmodifiable([
    createMinecraftAccount(
      id: _defaultAccountId,
      username: 'SteveOnline',
      accountType: AccountType.microsoft,
      microsoftAccountInfo: createMicrosoftAccountInfo(
        microsoftOAuthRefreshToken: ExpirableToken(
          value: 'refresh-token-1',
          expiresAt: DateTime.utc(2030, 10, 5),
        ),
        minecraftAccessToken: ExpirableToken(
          value: 'mc-access-token-1',
          expiresAt: DateTime.utc(2077, 1, 1),
        ),
      ),
      skins: [
        createMinecraftSkin(
          id: 'skin-1',
          state: MinecraftCosmeticState.active,
          url: 'https://textures.minecraft.net/skin1.png',
          textureKey: 'key-skin-1',
          variant: MinecraftSkinVariant.classic,
        ),
        createMinecraftSkin(
          id: 'skin-2',
          state: MinecraftCosmeticState.inactive,
          url: 'https://textures.minecraft.net/skin2.png',
          textureKey: 'key-skin-2',
          variant: MinecraftSkinVariant.slim,
        ),
      ],
      capes: [
        createMinecraftCape(
          id: 'cape-1',
          state: MinecraftCosmeticState.active,
          url: 'https://textures.minecraft.net/cape1.png',
          alias: 'migration',
        ),
        createMinecraftCape(
          id: 'cape-2',
          state: MinecraftCosmeticState.inactive,
          url: 'https://textures.minecraft.net/cape2.png',
          alias: 'common',
        ),
      ],
      ownsMinecraftJava: true,
    ),
    createMinecraftAccount(
      id: 'uuid-offline-1',
      username: 'AlexOffline',
      accountType: AccountType.offline,
      microsoftAccountInfo: null,
    ),
    createMinecraftAccount(
      id: targetAccountId,
      username: 'CreeperGuy',
      accountType: AccountType.microsoft,
      microsoftAccountInfo: createMicrosoftAccountInfo(
        microsoftOAuthRefreshToken: ExpirableToken(
          value: 'refresh-token-2',
          expiresAt: DateTime.utc(2099, 1, 1),
        ),
        minecraftAccessToken: ExpirableToken(
          value: 'mc-access-token-2',
          expiresAt: DateTime.utc(2031, 1, 1),
        ),
      ),
      skins: [
        createMinecraftSkin(
          id: 'skin-3',
          state: MinecraftCosmeticState.inactive,
          url: 'https://textures.minecraft.net/skin3.png',
          textureKey: 'key-skin-3',
          variant: MinecraftSkinVariant.classic,
        ),
      ],
      capes: [
        createMinecraftCape(
          id: 'cape-2',
          state: MinecraftCosmeticState.inactive,
          url: 'https://textures.minecraft.net/cape2.png',
          alias: 'minecon',
        ),
      ],
      ownsMinecraftJava: true,
    ),
    createMinecraftAccount(
      id: 'uuid-offline-2',
      username: 'BuilderBob',
      accountType: AccountType.offline,
      microsoftAccountInfo: null,
    ),
  ]);

  static final MinecraftAccounts accounts = MinecraftAccounts(
    list: _list,
    defaultAccountId: _defaultAccountId,
  );
}

abstract final class MinecraftDummyAccount {
  static final account = createMinecraftAccount(
    id: 'player-id',
    username: 'player_username',
    accountType: AccountType.microsoft,
    microsoftAccountInfo: createMicrosoftAccountInfo(
      microsoftOAuthRefreshToken: createExpirableToken(
        value: 'microsoft-refresh-token',
        expiresAt: DateTime(2016),
      ),
      minecraftAccessToken: createExpirableToken(
        value: 'minecraft-access-token',
        expiresAt: DateTime(2022, 1, 20, 15, 40),
      ),
    ),
    skins: [
      createMinecraftSkin(
        id: 'id',
        state: MinecraftCosmeticState.active,
        url: 'http://dasdsas',
        textureKey: 'dasdsadsadsa',
        variant: MinecraftSkinVariant.classic,
      ),
      createMinecraftSkin(
        id: 'iadsadasd',
        state: MinecraftCosmeticState.inactive,
        url: 'http://dasddsadsasas',
        textureKey: 'dsad2sadsadsa',
        variant: MinecraftSkinVariant.slim,
      ),
    ],
    capes: [
      createMinecraftCape(
        id: 'cape-1',
        state: MinecraftCosmeticState.active,
        url: 'https://textures.minecraft.net/cape1.png',
        alias: 'migration',
      ),
      createMinecraftCape(
        id: 'cape-2',
        state: MinecraftCosmeticState.inactive,
        url: 'https://textures.minecraft.net/cape2.png',
        alias: 'common',
      ),
    ],
    ownsMinecraftJava: true,
  );
}
