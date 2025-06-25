import 'dart:convert';
import 'dart:io';

import '../../../../common/logic/app_data_paths.dart';
import '../../../../common/logic/json.dart';
import 'file_accounts.dart';

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
