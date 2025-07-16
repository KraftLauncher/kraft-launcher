import 'dart:convert';
import 'dart:io';

import 'package:kraft_launcher/common/data/json.dart';

typedef FromJson<T> = T Function(JsonMap json);

class JsonFileCache<T> {
  JsonFileCache({required T Function(Map<String, Object?>) fromJson})
    : _fromJson = fromJson;

  final FromJson<T> _fromJson;

  // Missing or corrupt cache is not a fatal error.
  // Silent [FormatException] and [FileSystemException].
  Future<T?> readFromFile(File file) async {
    try {
      if (!file.existsSync()) {
        return null;
      }
      // TODO: Unrelated to this file: All File IO operations should handle FileSystemException, currently
      //  SettingsFileStorage.readSettings and AccountFileStorage.readAccounts does not.
      final content = await file.readAsString();
      final json = jsonDecode(content) as JsonMap;
      return _fromJson(json);
    } on FormatException {
      return null;
    } on FileSystemException {
      return null;
    }
  }

  Future<void> writeToFile(File file, JsonMap map) async {
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncodePretty(map));
  }
}
