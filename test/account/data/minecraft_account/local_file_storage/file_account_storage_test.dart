import 'package:file/memory.dart';
import 'package:kraft_launcher/account/data/launcher_minecraft_account/local_file_storage/file_account_storage.dart';
import 'package:kraft_launcher/account/data/launcher_minecraft_account/local_file_storage/file_accounts.dart';
import 'package:kraft_launcher/account/data/launcher_minecraft_account/local_file_storage/mappers/accounts_mapper.dart';
import 'package:test/test.dart';

import '../../minecraft_dummy_accounts.dart';

void main() {
  late FileAccountStorage fileAccountStorage;
  late MemoryFileSystem memoryFileSystem;

  setUp(() {
    memoryFileSystem = MemoryFileSystem.test();
    fileAccountStorage = FileAccountStorage(
      file: memoryFileSystem.file('accounts.json'),
    );
  });

  final dummyAccounts = MinecraftDummyAccounts.accounts.toFileModel(
    storeTokensInFile: true,
  );

  Future<FileAccounts> readAccountsNotNull() async {
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
      final file = fileAccountStorage.file;
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
      final file = fileAccountStorage.file;
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
