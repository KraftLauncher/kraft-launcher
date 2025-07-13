import 'dart:convert';
import 'dart:io';

import 'package:kraft_launcher/account/data/launcher_minecraft_account/local_file_storage/file_minecraft_accounts.dart';
import 'package:kraft_launcher/common/data/json.dart';
import 'package:kraft_launcher/common/logic/app_data_paths.dart';
import 'package:meta/meta.dart';

// TODO: Extract interface `AccountFileStorage` and rename this class to `LocalAccountFileStorage`.
//  Apply the same pattern to other data sources.

class FileAccountStorage {
  FileAccountStorage({required this.file});
  factory FileAccountStorage.fromAppDataPaths(AppDataPaths appDataPaths) =>
      FileAccountStorage(file: appDataPaths.accounts);

  @visibleForTesting
  final File file;

  Future<FileMinecraftAccounts?> readAccounts() async {
    if (!file.existsSync()) {
      return null;
    }

    final fileContent = (await file.readAsString()).trim();
    if (fileContent.isEmpty) {
      return null;
    }

    return FileMinecraftAccounts.fromJson(jsonDecode(fileContent) as JsonMap);
  }

  Future<void> saveAccounts(FileMinecraftAccounts accounts) =>
      file.writeAsString(jsonEncodePretty(accounts.toJson()));
}
