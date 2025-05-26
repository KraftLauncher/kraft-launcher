import 'dart:convert';
import 'dart:io';

import '../../../common/logic/app_data_paths.dart';
import '../../../common/logic/json.dart';
import '../minecraft_accounts.dart';

class AccountStorage {
  AccountStorage({required this.file});

  factory AccountStorage.fromAppDataPaths(AppDataPaths appDataPaths) =>
      AccountStorage(file: appDataPaths.accounts);

  final File file;

  MinecraftAccounts loadAccounts() {
    MinecraftAccounts saveEmptyAccounts() {
      final emptyAccounts = MinecraftAccounts.empty();
      saveAccounts(emptyAccounts);
      return emptyAccounts;
    }

    if (!file.existsSync()) {
      return saveEmptyAccounts();
    }

    final fileContent = file.readAsStringSync().trim();
    if (fileContent.isEmpty) {
      return saveEmptyAccounts();
    }

    return MinecraftAccounts.fromJson(jsonDecode(fileContent) as JsonObject);
  }

  // TODO: Avoid writeAsStringSync, read: https://dart.dev/tools/linter-rules/avoid_slow_async_io
  void saveAccounts(MinecraftAccounts accounts) {
    file.writeAsStringSync(jsonEncodePretty(accounts.toJson()));
  }
}
