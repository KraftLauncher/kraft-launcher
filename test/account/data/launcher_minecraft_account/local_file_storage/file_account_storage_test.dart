import 'dart:io' show File;

import 'package:file/memory.dart';
import 'package:kraft_launcher/account/data/launcher_minecraft_account/local_file_storage/file_account_storage.dart';
import 'package:kraft_launcher/account/data/launcher_minecraft_account/local_file_storage/file_minecraft_accounts.dart';
import 'package:kraft_launcher/account/data/launcher_minecraft_account/local_file_storage/mappers/accounts_mapper.dart';
import 'package:test/test.dart';

import '../../minecraft_dummy_accounts.dart';

void main() {
  late MemoryFileSystem memoryFileSystem;
  late File file;

  late FileAccountStorage fileAccountStorage;

  setUp(() {
    memoryFileSystem = MemoryFileSystem.test();
    file = memoryFileSystem.file('accounts.json');

    fileAccountStorage = FileAccountStorage(file: file);
  });

  final dummyAccounts = MinecraftDummyAccounts.accounts.toFileDto(
    storeTokensInFile: true,
  );

  Future<FileMinecraftAccounts> readAccountsNotNull() async {
    final accounts = await fileAccountStorage.readAccounts();

    if (accounts == null) {
      fail(
        'Expected to read non-null accounts after saving, but got null. This suggests the save or read operation did not succeed. There might be a bug in this test.',
      );
    }

    return accounts;
  }

  group('readAccounts', () {
    test('returns null if file does not exist', () async {
      expect(file.existsSync(), false);

      final accounts = await fileAccountStorage.readAccounts();
      expect(accounts, null);

      expect(
        file.existsSync(),
        false,
        reason:
            'The file should not be created when calling readAccounts if it does not already exist.',
      );
    });

    test('returns null if file exists but is empty', () async {
      await file.create();
      expect(file.existsSync(), true);
      expect(await file.readAsString(), '');

      final accounts = await fileAccountStorage.readAccounts();
      expect(accounts, null);

      expect(
        await file.readAsString(),
        '',
        reason:
            'The file should not be modified when calling readAccounts if file is already empty.',
      );
    });

    test('parses saved accounts correctly', () async {
      final accountsToSave = dummyAccounts;
      await fileAccountStorage.saveAccounts(accountsToSave);

      final savedAccounts = await readAccountsNotNull();

      expect(savedAccounts.toJson(), accountsToSave.toJson());
      expect(savedAccounts, accountsToSave);
    });
  });

  test('saveAccounts writes accounts correctly to disk', () async {
    final accountsToSave = dummyAccounts;
    await fileAccountStorage.saveAccounts(accountsToSave);

    final savedAccounts = await readAccountsNotNull();

    expect(savedAccounts.toJson(), accountsToSave.toJson());
    expect(savedAccounts, accountsToSave);
  });
}
