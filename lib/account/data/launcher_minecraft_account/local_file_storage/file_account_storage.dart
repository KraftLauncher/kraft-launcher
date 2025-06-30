import 'dart:convert';
import 'dart:io';

import 'package:kraft_launcher/account/data/launcher_minecraft_account/local_file_storage/file_accounts.dart';
import 'package:kraft_launcher/common/logic/app_data_paths.dart';
import 'package:kraft_launcher/common/logic/json.dart';

class FileAccountStorage {
  FileAccountStorage({required this.file});
  factory FileAccountStorage.fromAppDataPaths(AppDataPaths appDataPaths) =>
      FileAccountStorage(file: appDataPaths.accounts);

  final File file;

  Future<FileAccounts?> readAccounts() async {
    if (!file.existsSync()) {
      return null;
    }

    final fileContent = (await file.readAsString()).trim();
    if (fileContent.isEmpty) {
      return null;
    }

    return FileAccounts.fromJson(jsonDecode(fileContent) as JsonMap);
  }

  Future<void> saveAccounts(FileAccounts accounts) =>
      file.writeAsString(jsonEncodePretty(accounts.toJson()));
}
