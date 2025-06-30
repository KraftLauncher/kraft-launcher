import 'package:uuid/uuid.dart';

import '../launcher_minecraft_account/minecraft_account.dart';

class MinecraftOfflineAccountFactory {
  Future<MinecraftAccount> createOfflineAccount({
    required String username,
  }) async {
    final newAccount = MinecraftAccount(
      accountType: AccountType.offline,
      id: const Uuid().v4(),
      username: username,
      microsoftAccountInfo: null,
      skins: List.unmodifiable([]),
      capes: List.unmodifiable([]),
      ownsMinecraftJava: null,
    );

    return newAccount;
  }

  Future<MinecraftAccount> updateOfflineAccount({
    required MinecraftAccount existingAccount,
    required String username,
  }) async {
    final updatedAccount = existingAccount.copyWith(username: username);

    return updatedAccount;
  }
}
