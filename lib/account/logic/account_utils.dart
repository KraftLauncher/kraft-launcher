import '../data/minecraft_account.dart';
import '../data/minecraft_accounts.dart';

// TODO: Add tests, and make use of updateById when possible

extension AccountsListUpdater on List<MinecraftAccount> {
  List<MinecraftAccount> updateById(
    String id,
    MinecraftAccount Function(MinecraftAccount account) update,
  ) {
    final index = indexWhere((account) => account.id == id);
    if (index == -1) {
      throw Exception(
        'Account with id $id was not found in the list: ${toString()}',
      );
    }
    final existingAccount = this[index];
    return List<MinecraftAccount>.from(this)..[index] = update(existingAccount);
  }
}

extension AccountsUpdater on MinecraftAccounts {
  MinecraftAccounts updateById(
    String id,
    MinecraftAccount Function(MinecraftAccount account) update,
  ) {
    return copyWith(all: all.updateById(id, update));
  }
}
