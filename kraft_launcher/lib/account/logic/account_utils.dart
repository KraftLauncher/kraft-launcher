import 'package:collection/collection.dart';
import 'package:kraft_launcher/account/logic/launcher_minecraft_account/minecraft_account.dart';
import 'package:kraft_launcher/common/logic/utils.dart';

extension AccountListByIdExt on List<MinecraftAccount> {
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

extension AccountListSearchExt on List<MinecraftAccount> {
  List<MinecraftAccount> filterByUsername(String searchQuery) {
    return where(
      (account) => account.username.trim().toLowerCase().contains(
        searchQuery.trim().toLowerCase(),
      ),
    ).toList();
  }
}
