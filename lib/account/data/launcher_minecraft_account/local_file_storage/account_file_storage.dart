import 'dart:io';

import 'package:kraft_launcher/account/data/launcher_minecraft_account/local_file_storage/file_minecraft_accounts.dart';
import 'package:kraft_launcher/common/data/json.dart';
import 'package:kraft_launcher/common/logic/app_data_paths.dart';

// TODO: Extract interface `AccountFileStorage` and rename this class to `LocalAccountFileStorage`.
//  Apply the same pattern to other data sources.
// TODO: Consider extracting common code between AccountFileStorage, SettingsAccountStorage and JsonFileCache.

class AccountFileStorage {
  AccountFileStorage({required File file}) : _file = file;

  factory AccountFileStorage.fromAppDataPaths(AppDataPaths appDataPaths) =>
      AccountFileStorage(file: appDataPaths.accounts);

  final File _file;

  Future<FileMinecraftAccounts?> readAccounts() async {
    if (!_file.existsSync()) {
      return null;
    }

    final fileContent = (await _file.readAsString()).trim();
    if (fileContent.isEmpty) {
      return null;
    }

    return FileMinecraftAccounts.fromJson(jsonDecode(fileContent));
  }

  Future<void> saveAccounts(FileMinecraftAccounts accounts) =>
      _file.writeAsString(jsonEncodePretty(accounts.toJson()));
}
