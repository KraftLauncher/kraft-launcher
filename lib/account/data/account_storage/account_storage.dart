import 'dart:convert';
import 'dart:io';

import '../../../common/logic/app_data_paths.dart';
import '../../../common/logic/json.dart';
import '../minecraft_accounts.dart';

class AccountStorage {
  AccountStorage({required this.accountsFile});

  factory AccountStorage.fromAppDataPaths(AppDataPaths appDataPaths) =>
      AccountStorage(accountsFile: appDataPaths.accounts);

  final File accountsFile;

  MinecraftAccounts loadAccounts() {
    MinecraftAccounts? minecraftAccounts;
    if (!accountsFile.existsSync()) {
      minecraftAccounts = MinecraftAccounts.empty();
      saveAccounts(minecraftAccounts);
    }
    final fileContent = accountsFile.readAsStringSync();
    if (fileContent.trim().isEmpty) {
      minecraftAccounts = MinecraftAccounts.empty();
      saveAccounts(minecraftAccounts);
    }
    return minecraftAccounts ??= MinecraftAccounts.fromJson(
      jsonDecode(fileContent) as JsonObject,
    );
  }

  // TODO: Avoid writeAsStringSync, read: https://dart.dev/tools/linter-rules/avoid_slow_async_io
  void saveAccounts(MinecraftAccounts accounts) {
    accountsFile.writeAsStringSync(jsonEncodePretty(accounts.toJson()));
  }
}
