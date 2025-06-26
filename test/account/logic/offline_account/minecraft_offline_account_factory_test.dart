import 'package:kraft_launcher/account/data/launcher_minecraft_account/minecraft_account.dart';
import 'package:kraft_launcher/account/logic/offline_account/minecraft_offline_account_factory.dart';
import 'package:test/test.dart';

import '../../data/minecraft_dummy_accounts.dart';

void main() {
  late MinecraftOfflineAccountFactory factory;

  setUp(() {
    factory = MinecraftOfflineAccountFactory();
  });
  group('createOfflineAccount', () {
    test('creates the account details correctly', () async {
      const username = 'example_username';
      final newAccount = await factory.createOfflineAccount(username: username);
      expect(newAccount.accountType, AccountType.offline);
      expect(newAccount.isMicrosoft, false);
      expect(newAccount.username, username);
      expect(newAccount.ownsMinecraftJava, null);
      expect(
        newAccount.skins,
        <MinecraftSkin>[],
        reason: 'Skins are not supported on offline accounts',
      );
      expect(
        newAccount.capes,
        <MinecraftCape>[],
        reason: 'Capes are not supported on offline accounts',
      );

      final uuidV4Regex = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
      );
      expect(newAccount.id, matches(uuidV4Regex));
    });

    test('creates unique id', () async {
      final id1 = (await factory.createOfflineAccount(username: '')).id;
      final id2 = (await factory.createOfflineAccount(username: '')).id;
      final id3 = (await factory.createOfflineAccount(username: '')).id;
      expect(id1, isNot(equals(id2)));
      expect(id2, isNot(equals(id3)));
      expect(id3, isNot(equals(id1)));
    });
  });

  test('updateOfflineAccount updates the account correctly', () async {
    final originalAccount = MinecraftDummyAccounts.accounts.list.firstWhere(
      (account) => account.accountType == AccountType.offline,
    );

    const newUsername = 'new_player_username4';
    final updatedAccount = await factory.updateOfflineAccount(
      existingAccount: originalAccount,
      username: newUsername,
    );

    expect(
      updatedAccount.id,
      originalAccount.id,
      reason: 'The account ID should remain unchanged.',
    );
    expect(updatedAccount.accountType, AccountType.offline);
    expect(updatedAccount.isMicrosoft, false);
    expect(updatedAccount.microsoftAccountInfo, null);
    expect(updatedAccount.username, newUsername);
    expect(updatedAccount.skins, isEmpty);
    expect(updatedAccount, originalAccount.copyWith(username: newUsername));
  });
}
