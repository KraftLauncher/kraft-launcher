import '../../common/logic/utils.dart';
import '../data/minecraft_account/minecraft_account.dart';
import '../data/minecraft_account/minecraft_accounts.dart';

// TODO: Add tests, and make use of them when possible

extension AccountsListExt on List<MinecraftAccount> {
  List<MinecraftAccount> updateById(
    String id,
    MinecraftAccount Function(MinecraftAccount account) update,
  ) {
    final index = accountIndexById(id);
    final existingAccount = this[index];
    return List<MinecraftAccount>.unmodifiable(
      List.from(this)..[index] = update(existingAccount),
    );
  }

  int accountIndexById(String id) {
    final index = indexWhereOrNull((account) => account.id == id);
    if (index == null) {
      throw StateError(
        'Account with id $id was not found in the list: ${toString()}',
      );
    }
    return index;
  }

  MinecraftAccount accountById(String id) {
    return this[accountIndexById(id)];
  }
}

extension AccountsExt on MinecraftAccounts {
  MinecraftAccounts updateById(
    String id,
    MinecraftAccount Function(MinecraftAccount account) update,
  ) {
    return copyWith(list: list.updateById(id, update));
  }
}
