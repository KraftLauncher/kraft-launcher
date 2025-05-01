import 'package:kraft_launcher/account/data/account_storage/account_storage.dart';
import 'package:kraft_launcher/account/data/minecraft_account.dart';
import 'package:kraft_launcher/account/data/minecraft_accounts.dart';
import 'package:kraft_launcher/common/logic/app_data_paths.dart';
import 'package:kraft_launcher/common/logic/json.dart';
import 'package:test/test.dart';

import '../../../common/helpers/temp_file_utils.dart';

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
      expect(accounts.defaultAccountIndex, isNull);

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
    expect(accounts.defaultAccountIndex, isNull);

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
    final savedAccounts = MinecraftAccounts(
      all: [
        MinecraftAccount(
          id: 'id',
          username: 'Steve',
          accountType: AccountType.microsoft,
          microsoftAccountInfo: MicrosoftAccountInfo(
            microsoftOAuthAccessToken: ExpirableToken(
              value: 'ewdadwadwadwewaeadsadwadwadwawda',
              expiresAt: DateTime.now().add(const Duration(days: 1)),
            ),
            microsoftOAuthRefreshToken: 'microsoftOAuthRefreshToken',
            minecraftAccessToken: ExpirableToken(
              value: 'dsadsadsadasewaedadwda',
              expiresAt: DateTime.now(),
            ),
          ),
          skins: const [],
          ownsMinecraftJava: false,
        ),
        MinecraftAccount(
          id: 'id',
          username: 'Steve',
          accountType: AccountType.microsoft,
          microsoftAccountInfo: MicrosoftAccountInfo(
            microsoftOAuthAccessToken: ExpirableToken(
              value: 'ewdadwadwadwewaeadsadwadwadwawda',
              expiresAt: DateTime.now().add(const Duration(hours: 12)),
            ),
            microsoftOAuthRefreshToken: 'microsoftOAuthRefreshToken',
            minecraftAccessToken: ExpirableToken(
              value: 'dsadsadsadasewaedadwdadfasdsadsa',
              expiresAt: DateTime.now().add(const Duration(days: 3)),
            ),
          ),
          skins: const [
            MinecraftSkin(
              id: 'id',
              state: 'ACTIVE',
              url: 'url',
              textureKey: 'textureKey',
              variant: MinecraftSkinVariant.slim,
            ),
          ],
          ownsMinecraftJava: true,
        ),
      ],
      defaultAccountIndex: null,
    );
    accountStorage.saveAccounts(savedAccounts);

    expect(accountStorage.loadAccounts().toJson(), savedAccounts.toJson());
  });

  test('saveAccounts writes accounts correctly to disk', () {
    final expectedAccounts = MinecraftAccounts(
      all: [
        MinecraftAccount(
          id: 'id',
          username: 'Steve',
          accountType: AccountType.microsoft,
          microsoftAccountInfo: MicrosoftAccountInfo(
            microsoftOAuthAccessToken: ExpirableToken(
              value: 'ewdadwadwadwewaeadsadwadwadwawda',
              expiresAt: DateTime.now().add(const Duration(days: 1)),
            ),
            microsoftOAuthRefreshToken: 'microsoftOAuthRefreshToken',
            minecraftAccessToken: ExpirableToken(
              value: 'dsadsadsadasewaedadwda',
              expiresAt: DateTime.now(),
            ),
          ),
          skins: const [],
          ownsMinecraftJava: false,
        ),
        MinecraftAccount(
          id: 'id',
          username: 'Steve',
          accountType: AccountType.microsoft,
          microsoftAccountInfo: MicrosoftAccountInfo(
            microsoftOAuthAccessToken: ExpirableToken(
              value: 'ewdadwadwadwewaeadsadwadwadwawda',
              expiresAt: DateTime.now().add(const Duration(hours: 12)),
            ),
            microsoftOAuthRefreshToken: 'microsoftOAuthRefreshToken',
            minecraftAccessToken: ExpirableToken(
              value: 'dsadsadsadasewaedadwdadfasdsadsa',
              expiresAt: DateTime.now().add(const Duration(days: 3)),
            ),
          ),
          skins: const [
            MinecraftSkin(
              id: 'id',
              state: 'ACTIVE',
              url: 'url',
              textureKey: 'textureKey',
              variant: MinecraftSkinVariant.slim,
            ),
          ],
          ownsMinecraftJava: true,
        ),
      ],
      defaultAccountIndex: null,
    );
    accountStorage.saveAccounts(expectedAccounts);
    final accounts = accountStorage.loadAccounts();
    expect(accounts.toJson(), expectedAccounts.toJson());
  });
}
