import 'package:kraft_launcher/account/data/account_storage/account_storage.dart';
import 'package:kraft_launcher/account/data/minecraft_accounts.dart';
import 'package:kraft_launcher/common/logic/app_data_paths.dart';
import 'package:kraft_launcher/common/logic/json.dart';
import 'package:test/test.dart';

import '../../../common/helpers/temp_file_utils.dart';
import '../minecraft_dummy_accounts.dart';

// TODO: Avoid IO operations.

void main() {
  late AppDataPaths appDataPaths;
  late AccountStorage accountStorage;

  setUp(() {
    appDataPaths = AppDataPaths(workingDirectory: createTempTestDir());
    accountStorage = AccountStorage.fromAppDataPaths(appDataPaths);
  });

  tearDown(() => appDataPaths.workingDirectory.deleteSync(recursive: true));

  test(
    'loadAccounts creates and returns empty accounts if file does not exist',
    () {
      final accountsFile = appDataPaths.accounts;
      expect(accountsFile.existsSync(), false);

      final accounts = accountStorage.loadAccounts();

      expect(accountsFile.existsSync(), true);

      expect(accounts.all, isEmpty);
      expect(accounts.defaultAccountId, isNull);

      expect(accounts.toJson(), MinecraftAccounts.empty().toJson());
    },
  );

  test('loadAccounts overwrites file if file exists but is empty', () {
    final accountsFile = appDataPaths.accounts;
    accountsFile.createSync();
    expect(accountsFile.existsSync(), true);
    expect(accountsFile.readAsStringSync(), '');

    final accounts = accountStorage.loadAccounts();
    expect(accounts.all, isEmpty);
    expect(accounts.defaultAccountId, isNull);

    expect(
      accountStorage.loadAccounts().toJson(),
      MinecraftAccounts.empty().toJson(),
    );
    expect(
      accountsFile.readAsStringSync(),
      jsonEncodePretty(MinecraftAccounts.empty().toJson()),
    );
  });

  test('loadAccounts parses saved accounts correctly', () {
    final savedAccounts = MinecraftDummyAccounts.accounts;
    accountStorage.saveAccounts(savedAccounts);

    expect(accountStorage.loadAccounts().toJson(), savedAccounts.toJson());
  });

  test('saveAccounts writes accounts correctly to disk', () {
    final expectedAccounts = MinecraftDummyAccounts.accounts;
    accountStorage.saveAccounts(expectedAccounts);
    final accounts = accountStorage.loadAccounts();
    expect(accounts.toJson(), expectedAccounts.toJson());
  });
}
