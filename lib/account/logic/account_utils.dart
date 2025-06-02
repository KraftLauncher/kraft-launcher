import 'package:collection/collection.dart';

import '../../common/logic/utils.dart';
import '../data/minecraft_account/minecraft_account.dart';
import '../data/minecraft_account/minecraft_accounts.dart';

// TODO: Add tests, and make use of them when possible

extension AccountsListExt on List<MinecraftAccount> {
  List<MinecraftAccount> updateById(
    String id,
    MinecraftAccount Function(MinecraftAccount account) update,
  ) {
    final index = findIndexById(id);
    final existingAccount = this[index];
    return List<MinecraftAccount>.unmodifiable(
      List.from(this)..[index] = update(existingAccount),
    );
  }

  int findIndexById(String id) {
    final index = indexWhereOrNull((account) => account.id == id);
    if (index == null) {
      throw ArgumentError.value(
        id,
        'id',
        'Account with id `$id` was not found in the list: ${toString()}',
      );
    }
    return index;
  }

  MinecraftAccount findById(String id) {
    final account = firstWhereOrNull((account) => account.id == id);
    if (account == null) {
      throw ArgumentError.value(
        id,
        'id',
        'Account with id `$id` was not found in the list: ${toString()}',
      );
    }
    return account;
  }
}

extension AccountsExt on MinecraftAccounts {
  // TODO: Avoid using this API? We should not need it once we're finished with some refactoring.
  MinecraftAccounts updateById(
    String id,
    MinecraftAccount Function(MinecraftAccount account) update,
  ) {
    return copyWith(list: list.updateById(id, update));
  }
}
