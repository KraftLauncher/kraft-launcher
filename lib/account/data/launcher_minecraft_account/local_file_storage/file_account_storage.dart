import 'dart:convert';
import 'dart:io';

import 'package:kraft_launcher/account/data/launcher_minecraft_account/local_file_storage/file_minecraft_accounts.dart';
import 'package:kraft_launcher/common/data/json.dart';
import 'package:kraft_launcher/common/logic/app_data_paths.dart';

// TODO: Extract interface `AccountFileStorage` and rename this class to `LocalAccountFileStorage`.
//  Apply the same pattern to other data sources.

class FileAccountStorage {
  FileAccountStorage({required File file}) : _file = file;
  factory FileAccountStorage.fromAppDataPaths(AppDataPaths appDataPaths) =>
      FileAccountStorage(file: appDataPaths.accounts);

  final File _file;

  Future<FileMinecraftAccounts?> readAccounts() async {
    if (!_file.existsSync()) {
      return null;
    }

    final fileContent = (await _file.readAsString()).trim();
    if (fileContent.isEmpty) {
      return null;
    }

    return FileMinecraftAccounts.fromJson(jsonDecode(fileContent) as JsonMap);
  }

  Future<void> saveAccounts(FileMinecraftAccounts accounts) =>
      _file.writeAsString(jsonEncodePretty(accounts.toJson()));
}
