import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kraft_launcher/account/data/launcher_minecraft_account/secure_storage/secure_account_data.dart';
import 'package:kraft_launcher/common/constants/project_info_constants.dart';
import 'package:kraft_launcher/common/data/json.dart';

class SecureAccountStorage {
  SecureAccountStorage({required FlutterSecureStorage flutterSecureStorage})
    : _flutterSecureStorage = flutterSecureStorage;

  final FlutterSecureStorage _flutterSecureStorage;

  String _storageKey(String accountId) => 'account_$accountId';

  Future<SecureAccountData?> read(String accountId) async {
    final key = _storageKey(accountId);
    final jsonString = await _flutterSecureStorage.read(key: key);
    if (jsonString == null) {
      return null;
    }
    return SecureAccountData.fromJson(jsonDecode(jsonString) as JsonMap);
  }

  Future<void> delete(String accountId) =>
      _flutterSecureStorage.delete(key: _storageKey(accountId));

  Future<void> write(
    String accountId,
    SecureAccountData secureAccountData,
  ) => _flutterSecureStorage.write(
    key: _storageKey(accountId),
    value: jsonEncode(secureAccountData.toJson()),
    mOptions: MacOsOptions(
      accountName: ProjectInfoConstants.macOSKeychainAppName,
      label: 'Minecraft Account [$accountId]',
      description:
          'Stored by ${ProjectInfoConstants.displayName} – secure credentials for account ID $accountId',
    ),
  );
}
