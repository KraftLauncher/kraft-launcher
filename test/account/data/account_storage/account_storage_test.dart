import 'package:kraft_launcher/account/data/account_storage/account_storage.dart';
import 'package:kraft_launcher/account/data/minecraft_account.dart';
import 'package:kraft_launcher/account/data/minecraft_accounts.dart';
import 'package:kraft_launcher/common/logic/app_data_paths.dart';
import 'package:kraft_launcher/common/logic/json.dart';
import 'package:test/test.dart';

import '../../../common/helpers/temp_file_utils.dart';

// TODO: Avoid creating MinecraftAccount directlt (use createMinecraftAccount() instead), avoid IO operations.

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
    final savedAccounts = MinecraftAccounts(
      all: [
        MinecraftAccount(
          id: 'id',
          username: 'Steve',
          accountType: AccountType.microsoft,
          microsoftAccountInfo: MicrosoftAccountInfo(
            microsoftOAuthAccessToken: ExpirableToken(
              value: 'ewdadwadwadwewaeadsadwadwadwawda',
              expiresAt: DateTime(2030, 5, 20, 14, 9),
            ),
            microsoftOAuthRefreshToken: ExpirableToken(
              value: 'microsoftOAuthRefreshToken2',
              expiresAt: DateTime(2020, 4, 18, 14, 9),
            ),
            minecraftAccessToken: ExpirableToken(
              value: 'dsadsadsadasewaedadwda',
              expiresAt: DateTime(2015, 3, 18, 14, 9),
            ),
            needsReAuthentication: true,
          ),
          skins: const [],
          ownsMinecraftJava: false,
        ),
        const MinecraftAccount(
          id: 'id2',
          username: 'Steve2',
          accountType: AccountType.offline,
          microsoftAccountInfo: null,
          skins: [],
          ownsMinecraftJava: null,
        ),
        MinecraftAccount(
          id: 'id',
          username: 'Steve',
          accountType: AccountType.microsoft,
          microsoftAccountInfo: MicrosoftAccountInfo(
            microsoftOAuthAccessToken: ExpirableToken(
              value: 'ewdadwadwadwewaeadsadwadwadwawda',
              expiresAt: DateTime(2014, 3, 18, 14, 9),
            ),
            microsoftOAuthRefreshToken: ExpirableToken(
              value: 'microsoftOAuthRefreshToken',
              expiresAt: DateTime(2015, 3, 18, 14, 9),
            ),
            minecraftAccessToken: ExpirableToken(
              value: 'dsadsadsadasewaedadwdadfasdsadsa',
              expiresAt: DateTime(2077, 11, 18, 14, 9),
            ),
            needsReAuthentication: false,
          ),
          skins: const [
            MinecraftSkin(
              id: 'id',
              state: MinecraftCosmeticState.active,
              url: 'url',
              textureKey: 'textureKey',
              variant: MinecraftSkinVariant.slim,
            ),
          ],
          ownsMinecraftJava: true,
        ),
      ],
      defaultAccountId: null,
    );
    accountStorage.saveAccounts(savedAccounts);

    expect(accountStorage.loadAccounts().toJson(), savedAccounts.toJson());
  });

  test('saveAccounts writes accounts correctly to disk', () {
    final expectedAccounts = MinecraftAccounts(
      all: [
        const MinecraftAccount(
          id: 'id2',
          username: 'Steve2',
          accountType: AccountType.offline,
          microsoftAccountInfo: null,
          skins: [],
          ownsMinecraftJava: null,
        ),
        MinecraftAccount(
          id: 'id',
          username: 'Steve',
          accountType: AccountType.microsoft,
          microsoftAccountInfo: MicrosoftAccountInfo(
            microsoftOAuthAccessToken: ExpirableToken(
              value: 'ewdadwadwadwewaeadsadwadwadwawda',
              expiresAt: DateTime(2019, 7, 18, 14, 9),
            ),
            microsoftOAuthRefreshToken: ExpirableToken(
              value: 'ewdadwadwadwewaeadsadwadadsdawadwawda',
              expiresAt: DateTime(2017, 2, 16, 14, 9),
            ),
            minecraftAccessToken: ExpirableToken(
              value: 'dsadsadsadasewaedadwda',
              expiresAt: DateTime(2013, 3, 12, 14, 9),
            ),
            needsReAuthentication: true,
          ),
          skins: const [],
          ownsMinecraftJava: false,
        ),
        MinecraftAccount(
          id: 'id2',
          username: 'Steve',
          accountType: AccountType.microsoft,
          microsoftAccountInfo: MicrosoftAccountInfo(
            microsoftOAuthAccessToken: ExpirableToken(
              value: 'ewdadwadwadwewaeadsadwadwadwawda',
              expiresAt: DateTime(2020, 3, 28, 14, 9),
            ),
            microsoftOAuthRefreshToken: ExpirableToken(
              value: 'ewdadwadwadwewaeadsadwadadsadsdsdawadwawda',
              expiresAt: DateTime(2019, 4, 18, 14, 9),
            ),
            minecraftAccessToken: ExpirableToken(
              value: 'dsadsadsadasewaedadwdadfasdsadsa',
              expiresAt: DateTime(2014, 4, 18, 14, 9),
            ),
            needsReAuthentication: false,
          ),
          skins: const [
            MinecraftSkin(
              id: 'id',
              state: MinecraftCosmeticState.inactive,
              url: 'url',
              textureKey: 'textureKey',
              variant: MinecraftSkinVariant.slim,
            ),
          ],
          ownsMinecraftJava: true,
        ),
      ],
      defaultAccountId: 'id2',
    );
    accountStorage.saveAccounts(expectedAccounts);
    final accounts = accountStorage.loadAccounts();
    expect(accounts.toJson(), expectedAccounts.toJson());
  });
}
