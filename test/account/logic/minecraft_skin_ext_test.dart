import 'package:kraft_launcher/account/logic/launcher_minecraft_account/minecraft_account.dart';
import 'package:kraft_launcher/account/logic/minecraft_skin_ext.dart';
import 'package:test/test.dart';

import '../data/minecraft_account_utils.dart';

const _steveUserId = 'f498513c-e8c8-3773-be26-ecfc7ed5185d';

void main() {
  group('fullSkinImageUrl', () {
    _commonTests(
      onlineSkinImageUrlProvider: (account) => account.fullSkinImageUrl,
      expectedSkinImageUrl:
          (accountId) =>
              'https://api.mineatar.io/body/full/$accountId?scale=8&overlay=true',
    );
  });

  group('headSkinImageUrl', () {
    _commonTests(
      onlineSkinImageUrlProvider: (account) => account.headSkinImageUrl,
      expectedSkinImageUrl:
          (accountId) => 'https://api.mineatar.io/face/$accountId?overlay=true',
    );
  });
}

void _commonTests({
  required String Function(MinecraftAccount account) onlineSkinImageUrlProvider,
  required String Function(String accountId) expectedSkinImageUrl,
}) {
  test('uses Steve skin user id for offline accounts', () {
    expect(
      onlineSkinImageUrlProvider(
        _account(accountType: AccountType.offline, accountId: _steveUserId),
      ),
      expectedSkinImageUrl(_steveUserId),
    );
  });
  test('uses correct user id for online accounts', () {
    const accountId = 'example-account-id';
    expect(
      onlineSkinImageUrlProvider(
        _account(accountType: AccountType.microsoft, accountId: accountId),
      ),
      expectedSkinImageUrl(accountId),
    );
  });

  test(
    'appends unique skin id for current active skin when skins are not empty',
    () {
      const accountId = 'example-account-id-2';
      const currentActiveSkinId = 'id';

      final account = _account(
        accountType: AccountType.microsoft,
        accountId: accountId,
        skins: [
          const MinecraftSkin(
            id: currentActiveSkinId,
            state: MinecraftCosmeticState.active,
            url: 'http://skin.png',
            textureKey: 'dasdsadasad',
            variant: MinecraftSkinVariant.slim,
          ),
          const MinecraftSkin(
            id: 'id2',
            state: MinecraftCosmeticState.inactive,
            url: 'http://skin.png',
            textureKey: 'dasdsadasad',
            variant: MinecraftSkinVariant.slim,
          ),
          const MinecraftSkin(
            id: 'id3',
            state: MinecraftCosmeticState.inactive,
            url: 'http://skin.png',
            textureKey: 'dasdsadasad',
            variant: MinecraftSkinVariant.slim,
          ),
        ],
      );
      expect(
        onlineSkinImageUrlProvider(account),
        '${expectedSkinImageUrl(accountId)}&skinId=${account.activeSkin!.id}',
      );
    },
  );
}

MinecraftAccount _account({
  AccountType accountType = AccountType.offline,
  MicrosoftAccountInfo? microsoftAccountInfo,
  List<MinecraftSkin> skins = const [],
  String accountId = '',
}) => createMinecraftAccount(
  accountType: accountType,
  id: accountId,
  microsoftAccountInfo: microsoftAccountInfo,
  skins: skins,
);
