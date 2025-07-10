import 'dart:async';

import 'package:clock/clock.dart';
import 'package:kraft_launcher/account/data/launcher_minecraft_account/local_file_storage/file_account_storage.dart';
import 'package:kraft_launcher/account/data/launcher_minecraft_account/local_file_storage/file_accounts.dart';
import 'package:kraft_launcher/account/data/launcher_minecraft_account/local_file_storage/mappers/accounts_mapper.dart';
import 'package:kraft_launcher/account/data/launcher_minecraft_account/secure_storage/secure_account_data.dart';
import 'package:kraft_launcher/account/data/launcher_minecraft_account/secure_storage/secure_account_storage.dart';
import 'package:kraft_launcher/account/logic/account_utils.dart';
import 'package:kraft_launcher/account/logic/launcher_minecraft_account/account_repository.dart';
import 'package:kraft_launcher/account/logic/launcher_minecraft_account/minecraft_account.dart';
import 'package:kraft_launcher/account/logic/launcher_minecraft_account/minecraft_accounts.dart';
import 'package:kraft_launcher/account/logic/platform_secure_storage_support.dart';
import 'package:kraft_launcher/common/logic/utils.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../common/test_constants.dart';
import '../../data/minecraft_account_utils.dart';
import '../../data/minecraft_dummy_accounts.dart';

late AccountRepository _accountRepository;

late _MockAccountsStreamController _mockAccountsStreamController;
late _MockFileAccountStorage _mockFileAccountStorage;
late _MockSecureAccountStorage _mockSecureAccountStorage;
late _MockPlatformSecureStorageSupport _mockPlatformSecureStorageSupport;

void main() {
  setUp(() {
    _mockAccountsStreamController = _MockAccountsStreamController();
    _mockFileAccountStorage = _MockFileAccountStorage();
    _mockSecureAccountStorage = _MockSecureAccountStorage();
    _mockPlatformSecureStorageSupport = _MockPlatformSecureStorageSupport();
    _accountRepository = AccountRepository(
      fileAccountStorage: _mockFileAccountStorage,
      secureAccountStorage: _mockSecureAccountStorage,
      secureStorageSupport: _mockPlatformSecureStorageSupport,
      accountsStreamControllerFactory: _mockAccountsStreamController,
    );

    when(
      () => _mockFileAccountStorage.saveAccounts(any()),
    ).thenAnswer((_) async {});
    when(
      () => _mockSecureAccountStorage.delete(any()),
    ).thenAnswer((_) async {});
    when(
      () => _mockSecureAccountStorage.write(any(), any()),
    ).thenAnswer((_) async {});
  });

  setUpAll(() {
    registerFallbackValue(
      MinecraftAccounts.empty().toFileDto(
        storeTokensInFile: _dummyStoreTokensInFile,
      ),
    );
    registerFallbackValue(
      const SecureAccountData(
        microsoftRefreshToken: 'dummy-refresh-token',
        minecraftAccessToken: 'dummy-access-token',
      ),
    );
  });

  group('accountsStream', () {
    test('uses $StreamController.broadcast by default', () {
      expect(
        AccountRepository(
          fileAccountStorage: _mockFileAccountStorage,
          secureAccountStorage: _mockSecureAccountStorage,
          secureStorageSupport: _mockPlatformSecureStorageSupport,
          accountsStreamControllerFactory: null,
        ).accountsStream.isBroadcast,
        true,
      );
    });

    test('reflects current internal state', () {
      final stream = Stream<MinecraftAccounts>.value(
        MinecraftDummyAccounts.accounts,
      );
      when(
        () => _mockAccountsStreamController.stream,
      ).thenAnswer((_) => stream);
      expect(_accountRepository.accountsStream, same(stream));
    });
  });

  group('supportsSecureStorage', () {
    test('throws $StateError when not initialized', () {
      expect(
        () => _accountRepository.supportsSecureStorageOrThrow,
        throwsStateError,
      );
    });

    test('reflects current internal state', () {
      for (final value in {true, false}) {
        _accountRepository.setSecureStorageSupportForTest(supported: value);

        final secureStorageSupported =
            _accountRepository.supportsSecureStorageOrThrow;
        expect(
          _accountRepository.supportsSecureStorageOrThrow,
          secureStorageSupported,
        );
      }
    });
  });

  group('accounts', () {
    test('throws $StateError when not initialized', () {
      expect(() => _accountRepository.accounts, throwsStateError);
    });

    test('list is unmodifiable', () {
      _accountRepository.setAccountsForTest(MinecraftAccounts.empty());
      expect(
        () => _accountRepository.accounts.list.add(createMinecraftAccount()),
        throwsUnsupportedError,
      );
    });

    test('reflects current internal state', () {
      final accounts = MinecraftDummyAccounts.accounts;
      _accountRepository.setAccountsForTest(accounts);

      expect(_accountRepository.accounts, equals(accounts));
      expect(
        _accountRepository.accounts,
        isNot(same(accounts)),
        reason:
            'Should return a copy of $MinecraftAccounts but not the same internal instance',
      );
    });
  });

  group('loadAccounts', () {
    Future<MinecraftAccounts> loadAccountsWithFixedClock([
      DateTime? fixedDateTime,
    ]) async {
      return await withClock(
        Clock.fixed(fixedDateTime ?? DateTime(2020)),
        () async {
          return _accountRepository.loadAccounts();
        },
      );
    }

    setUp(() {
      when(() => _mockFileAccountStorage.readAccounts()).thenAnswer((_) async {
        return null;
      });
      when(
        () => _mockPlatformSecureStorageSupport.isSupported(),
      ).thenAnswer((_) async => false);
      when(
        () => _mockSecureAccountStorage.read(any()),
      ).thenAnswer((_) async => null);
    });

    test(
      'sets supportsSecureStorage based on $PlatformSecureStorageSupport',
      () async {
        for (final value in {true, false}) {
          when(
            () => _mockPlatformSecureStorageSupport.isSupported(),
          ).thenAnswer((_) async => value);

          await loadAccountsWithFixedClock();

          expect(_accountRepository.supportsSecureStorageOrThrow, value);
        }
      },
    );

    test('reads accounts from $FileAccountStorage correctly', () async {
      await loadAccountsWithFixedClock();

      verify(() => _mockFileAccountStorage.readAccounts()).called(1);
      verifyNoMoreInteractions(_mockFileAccountStorage);
    });

    test(
      'avoids writing empty accounts file when $FileAccountStorage.readAccounts() returns null',
      () async {
        when(() => _mockFileAccountStorage.readAccounts()).thenAnswer((
          _,
        ) async {
          return null;
        });
        await loadAccountsWithFixedClock();
        verifyNever(() => _mockFileAccountStorage.saveAccounts(any()));
      },
    );

    test(
      'initializes empty accounts when $FileAccountStorage.readAccounts() returns null',
      () async {
        when(() => _mockFileAccountStorage.readAccounts()).thenAnswer((
          _,
        ) async {
          return null;
        });
        final accounts = await loadAccountsWithFixedClock();
        final emptyAccounts = MinecraftAccounts.empty();

        expect(accounts, emptyAccounts);
        expect(_accountRepository.accounts, emptyAccounts);
      },
    );

    group('mapFileAccountsToAccounts', () {
      final accounts = MinecraftDummyAccounts.accounts;
      setUp(() {
        when(() => _mockFileAccountStorage.readAccounts()).thenAnswer((
          _,
        ) async {
          return accounts.toFileDto(storeTokensInFile: true);
        });
      });

      group('secure storage available', () {
        setUp(() {
          when(
            () => _mockPlatformSecureStorageSupport.isSupported(),
          ).thenAnswer((_) async => true);
        });

        test(
          'avoid reading from secure storage for ${AccountType.offline} accounts',
          () async {
            await loadAccountsWithFixedClock();

            for (final account in accounts.list) {
              if (account.isOffline) {
                verifyNever(() => _mockSecureAccountStorage.read(account.id));
              }
            }
          },
        );

        test(
          'reads from secure storage for ${AccountType.microsoft.name} accounts',
          () async {
            await loadAccountsWithFixedClock();

            for (final account in accounts.list) {
              if (account.isMicrosoft) {
                verify(
                  () => _mockSecureAccountStorage.read(account.id),
                ).called(1);
              }
            }
            verifyNoMoreInteractions(_mockSecureAccountStorage);
          },
        );

        test(
          'provides tokens from $SecureAccountData for ${AccountType.microsoft.name} accounts',
          () async {
            const secureAccountData = SecureAccountData(
              microsoftRefreshToken: 'example-microsoft-refresh-token',
              minecraftAccessToken: 'example-minecraft-access-token',
            );
            when(
              () => _mockSecureAccountStorage.read(any()),
            ).thenAnswer((_) async => secureAccountData);

            final loadedAccounts = await loadAccountsWithFixedClock();

            for (final account in loadedAccounts.list) {
              if (account.isMicrosoft) {
                expect(
                  account.microsoftAccountInfo?.microsoftRefreshToken.value,
                  secureAccountData.microsoftRefreshToken,
                  reason:
                      'Should match the Microsoft refresh token from $SecureAccountData',
                );
                expect(
                  account.microsoftAccountInfo?.minecraftAccessToken.value,
                  secureAccountData.minecraftAccessToken,
                  reason:
                      'Should match the Minecraft access token from $SecureAccountData',
                );
              }
            }
          },
        );

        test(
          'provides null for tokens and $MicrosoftReauthRequiredReason for ${AccountType.offline.name} accounts',
          () async {
            final loadedAccounts = await loadAccountsWithFixedClock();

            for (final account in loadedAccounts.list) {
              if (account.isOffline) {
                expect(account.microsoftAccountInfo, null);
                expect(
                  account.microsoftAccountInfo?.reauthRequiredReason,
                  null,
                );
              }
            }
          },
        );

        test(
          'sets $MicrosoftAccountInfo.reauthRequiredReason to ${MicrosoftReauthRequiredReason.tokensMissingFromSecureStorage} when $SecureAccountData is null for this account',
          () async {
            when(
              () => _mockSecureAccountStorage.read(any()),
            ).thenAnswer((_) async => null);

            final loadedAccounts = await loadAccountsWithFixedClock();

            for (final account in loadedAccounts.list) {
              if (account.isMicrosoft) {
                expect(
                  account.microsoftAccountInfo?.reauthRequiredReason,
                  MicrosoftReauthRequiredReason.tokensMissingFromSecureStorage,
                );
              }
            }
          },
        );

        test(
          'sets tokens in $MicrosoftAccountInfo to null when $SecureAccountData is null for this account',
          () async {
            when(
              () => _mockSecureAccountStorage.read(any()),
            ).thenAnswer((_) async => null);

            when(() => _mockFileAccountStorage.readAccounts()).thenAnswer((
              _,
            ) async {
              return accounts.toFileDto(storeTokensInFile: false);
            });

            final loadedAccounts = await loadAccountsWithFixedClock();

            for (final account in loadedAccounts.list) {
              if (account.isMicrosoft) {
                expect(
                  account.microsoftAccountInfo?.microsoftRefreshToken.value,
                  null,
                );
                expect(
                  account.microsoftAccountInfo?.minecraftAccessToken.value,
                  null,
                );
              }
            }
          },
        );
      });

      group('secure storage unavailable', () {
        setUp(() {
          when(
            () => _mockPlatformSecureStorageSupport.isSupported(),
          ).thenAnswer((_) async => false);
        });

        test('avoids reading from secure storage', () async {
          await loadAccountsWithFixedClock();
          verifyNever(() => _mockSecureAccountStorage.read(any()));
          verifyZeroInteractions(_mockSecureAccountStorage);
        });

        test(
          'sets $MicrosoftAccountInfo.reauthRequiredReason to ${MicrosoftReauthRequiredReason.tokensMissingFromFileStorage} when tokens not found in file',
          () async {
            when(() => _mockFileAccountStorage.readAccounts()).thenAnswer(
              (_) async => createMinecraftAccounts(
                list: [
                  createMinecraftAccount(
                    microsoftAccountInfo: createMicrosoftAccountInfo(
                      microsoftRefreshToken: createExpirableToken(
                        isValueNull: true,
                      ),
                      minecraftAccessToken: createExpirableToken(
                        isValueNull: true,
                      ),
                    ),
                  ),
                ],
              ).toFileDto(storeTokensInFile: true),
            );

            final loadedAccounts = await loadAccountsWithFixedClock();

            for (final account in loadedAccounts.list) {
              if (account.isMicrosoft) {
                expect(
                  account.microsoftAccountInfo?.reauthRequiredReason,
                  MicrosoftReauthRequiredReason.tokensMissingFromFileStorage,
                );
              }
            }
          },
        );
      });

      group(
        '${MicrosoftReauthRequiredReason.accessRevoked} and ${MicrosoftReauthRequiredReason.accessRevoked} when secure storage supported and unsupported',
        () {
          test(
            'returns ${MicrosoftReauthRequiredReason.accessRevoked} when accessRevoked is true in file',
            () async {
              for (final supportsSecureStorage in {true, false}) {
                when(
                  () => _mockPlatformSecureStorageSupport.isSupported(),
                ).thenAnswer((_) async => supportsSecureStorage);

                when(() => _mockFileAccountStorage.readAccounts()).thenAnswer(
                  (_) async => createMinecraftAccounts(
                    list: [
                      createMinecraftAccount(
                        microsoftAccountInfo: createMicrosoftAccountInfo(
                          // This might be confusing but the toFileAccounts
                          // will map this accessRevoked that's of value true.
                          reauthRequiredReason:
                              MicrosoftReauthRequiredReason.accessRevoked,
                        ),
                      ),
                    ],
                  ).toFileDto(storeTokensInFile: _dummyStoreTokensInFile),
                );

                final accounts = await loadAccountsWithFixedClock();
                expect(
                  accounts
                      .list
                      .first
                      .microsoftAccountInfo
                      ?.reauthRequiredReason,
                  MicrosoftReauthRequiredReason.accessRevoked,
                );
              }
            },
          );

          test(
            'returns ${MicrosoftReauthRequiredReason.refreshTokenExpired} when Microsoft refresh token is expired',
            () async {
              for (final supportsSecureStorage in {true, false}) {
                when(
                  () => _mockPlatformSecureStorageSupport.isSupported(),
                ).thenAnswer((_) async => supportsSecureStorage);

                final fixedDateTime = DateTime(2014);
                when(() => _mockFileAccountStorage.readAccounts()).thenAnswer(
                  (_) async => createMinecraftAccounts(
                    list: [
                      createMinecraftAccount(
                        accountType: AccountType.microsoft,
                        microsoftAccountInfo: createMicrosoftAccountInfo(
                          microsoftRefreshToken: createExpirableToken(
                            expiresAt: fixedDateTime.subtract(
                              const Duration(days: 1),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ).toFileDto(storeTokensInFile: _dummyStoreTokensInFile),
                );

                final accounts = await loadAccountsWithFixedClock(
                  fixedDateTime,
                );
                expect(
                  accounts
                      .list
                      .first
                      .microsoftAccountInfo
                      ?.reauthRequiredReason,
                  MicrosoftReauthRequiredReason.refreshTokenExpired,
                );
              }
            },
          );
        },
      );
    });

    test('accounts list is unmodifiable', () async {
      when(() => _mockFileAccountStorage.readAccounts()).thenAnswer((_) async {
        return MinecraftDummyAccounts.accounts.toFileDto(
          storeTokensInFile: _dummyStoreTokensInFile,
        );
      });

      final accounts = await loadAccountsWithFixedClock();
      expect(
        () => accounts.list.removeAt(0),
        throwsUnsupportedError,
        reason: 'The list returned by loadAccounts() must be unmodifiable',
      );
      expect(
        () => _accountRepository.accounts.list.removeAt(0),
        throwsUnsupportedError,
        reason:
            'The list exposed by $AccountRepository.accounts must be unmodifiable',
      );
    });

    _setAccountsAndNotifyTests((existingAccounts) async {
      when(() => _mockFileAccountStorage.readAccounts()).thenAnswer((_) async {
        return existingAccounts.toFileDto(storeTokensInFile: true);
      });

      await loadAccountsWithFixedClock();
      return (existingAccounts, 'Should load the accounts correctly from file');
    }, existingAccountsBuilder: () => MinecraftDummyAccounts.accounts);
  });
  group('addAccount', () {
    MinecraftAccounts getExpectedAccountsAfterCall({
      required MinecraftAccounts existingAccounts,
      required MinecraftAccount newAccount,
    }) {
      final expectedAccounts = existingAccounts.copyWith(
        list: List<MinecraftAccount>.unmodifiable([
          newAccount,
          ...existingAccounts.list,
        ]),
        defaultAccountId: Wrapped.value(
          existingAccounts.defaultAccountId ?? newAccount.id,
        ),
      );
      return expectedAccounts;
    }

    (MinecraftAccount newAccount, MinecraftAccounts existingAccounts)
    newAccountAndExistingAccounts() {
      final existingAccounts = createMinecraftAccounts(
        list: [
          createMinecraftAccount(
            id: 'minecraft-user-id',
            username: 'minecraft_username',
            accountType: AccountType.microsoft,
          ),
          createMinecraftAccount(
            id: 'minecraft-user-id-2',
            username: 'minecraft_username_2',
            accountType: AccountType.offline,
          ),
        ],
        defaultAccountId: 'minecraft-user-id-2',
      );

      final newAccount = createMinecraftAccount(
        id: 'new-minecraft-user-id',
        username: 'new_minecraft_username',
      );

      return (newAccount, existingAccounts);
    }

    _defaultAccountIdTests(
      isUpdate: true,
      accountAndExistingAccounts: () => newAccountAndExistingAccounts(),
      runActionUnderTest: (account) async {
        await _accountRepository.addAccount(account);
      },
    );

    _saveAccountsInFileStorageTests(({
      required bool supportsSecureStorage,
    }) async {
      final (newAccount, existingAccounts) = newAccountAndExistingAccounts();
      _setInternalState(
        accounts: existingAccounts,
        supportsSecureStorage: supportsSecureStorage,
      );
      await _accountRepository.addAccount(newAccount);
      return getExpectedAccountsAfterCall(
        existingAccounts: existingAccounts,
        newAccount: newAccount,
      );
    });

    _saveSecureAccountDataTests(
      ({required bool supportsSecureStorage}) async {
        final (newAccount, existingAccounts) = newAccountAndExistingAccounts();
        _setInternalState(
          accounts: existingAccounts,
          supportsSecureStorage: supportsSecureStorage,
        );
        await _accountRepository.addAccount(newAccount);
        return newAccount;
      },
      (accountWithNullTokens) async {
        await _accountRepository.addAccount(accountWithNullTokens);
      },
    );

    _setAccountsAndNotifyTests((existingAccounts) async {
      final (newAccount, _) = newAccountAndExistingAccounts();

      await _accountRepository.addAccount(newAccount);

      final expectedAccounts = getExpectedAccountsAfterCall(
        existingAccounts: existingAccounts,
        newAccount: newAccount,
      );
      return (expectedAccounts, 'Should add the account correctly');
    }, existingAccountsBuilder: () => newAccountAndExistingAccounts().$2);
  });

  group('updateAccount', () {
    (MinecraftAccount updatedAccount, MinecraftAccounts existingAccounts)
    updatedAccountAndExistingAccounts() {
      const id = 'minecraft-user-id';
      final existingAccounts = createMinecraftAccounts(
        list: [
          createMinecraftAccount(
            id: id,
            username: 'minecraft_username',
            accountType: AccountType.microsoft,
            ownsMinecraftJava: false,
            microsoftAccountInfo: createMicrosoftAccountInfo(
              microsoftRefreshToken: createExpirableToken(
                value: 'microsoft-refresh-token',
              ),
              minecraftAccessToken: createExpirableToken(
                value: 'minecraft-access-token',
              ),
            ),
            capes: [createMinecraftCape(), createMinecraftCape()],
            skins: [createMinecraftSkin(), createMinecraftSkin()],
          ),
          createMinecraftAccount(
            id: 'minecraft-user-id-2',
            username: 'minecraft_username_2',
            accountType: AccountType.offline,
          ),
        ],
        defaultAccountId: 'minecraft-user-id-2',
      );
      final updatedAccount = existingAccounts.list
          .findById(id)
          .copyWith(
            ownsMinecraftJava: true,
            username: 'updated_minecraft_username',
            microsoftAccountInfo: createMicrosoftAccountInfo(
              microsoftRefreshToken: createExpirableToken(
                value: 'updated-microsoft-refresh-token',
              ),
              minecraftAccessToken: createExpirableToken(
                value: 'updated-minecraft-access-token',
              ),
            ),
            capes: [createMinecraftCape(id: 'new-id'), createMinecraftCape()],
            skins: [createMinecraftSkin(url: 'new-url')],
          );
      return (updatedAccount, existingAccounts);
    }

    MinecraftAccounts getExpectedAccountsAfterCall({
      required MinecraftAccounts existingAccounts,
      required MinecraftAccount updatedAccount,
    }) => existingAccounts.copyWith(
      list: existingAccounts.list.updateById(
        updatedAccount.id,
        (_) => updatedAccount,
      ),
      defaultAccountId: Wrapped.value(
        existingAccounts.defaultAccountId ?? updatedAccount.id,
      ),
    );

    _defaultAccountIdTests(
      isUpdate: true,
      accountAndExistingAccounts: () => updatedAccountAndExistingAccounts(),
      runActionUnderTest: (account) async {
        await _accountRepository.updateAccount(account);
      },
    );

    _saveAccountsInFileStorageTests(({
      required bool supportsSecureStorage,
    }) async {
      final (updatedAccount, existingAccounts) =
          updatedAccountAndExistingAccounts();
      _setInternalState(
        accounts: existingAccounts,
        supportsSecureStorage: supportsSecureStorage,
      );

      await _accountRepository.updateAccount(updatedAccount);
      return getExpectedAccountsAfterCall(
        existingAccounts: existingAccounts,
        updatedAccount: updatedAccount,
      );
    });

    _saveSecureAccountDataTests(
      ({required bool supportsSecureStorage}) async {
        final (updatedAccount, existingAccounts) =
            updatedAccountAndExistingAccounts();
        _setInternalState(
          accounts: existingAccounts,
          supportsSecureStorage: supportsSecureStorage,
        );
        await _accountRepository.updateAccount(updatedAccount);
        return updatedAccount;
      },
      (accountWithNullTokens) async {
        await _accountRepository.updateAccount(accountWithNullTokens);
      },
    );

    _setAccountsAndNotifyTests((existingAccounts) async {
      final (updatedAccount, _) = updatedAccountAndExistingAccounts();

      await _accountRepository.updateAccount(updatedAccount);

      final expectedAccounts = getExpectedAccountsAfterCall(
        existingAccounts: existingAccounts,
        updatedAccount: updatedAccount,
      );
      return (expectedAccounts, 'Should update the account correctly');
    }, existingAccountsBuilder: () => updatedAccountAndExistingAccounts().$2);
  });

  group('removeAccount', () {
    MinecraftAccounts getExpectedAccountsAfterCall({
      required MinecraftAccounts existingAccounts,
      required String id,
    }) => existingAccounts.copyWith(
      list: List.from(existingAccounts.list)
        ..removeWhere((account) => account.id == id),
    );
    (String id, MinecraftAccounts) accountIdToRemoveAndExistingAccounts() {
      const id = 'minecraft-user-id';
      final existingAccounts = createMinecraftAccounts(
        list: [
          createMinecraftAccount(
            id: id,
            username: 'minecraft_username',
            accountType: AccountType.offline,
          ),
          createMinecraftAccount(
            id: 'minecraft-user-id-2',
            username: 'minecraft_username_2',
            // Ensure at least one Microsoft account with tokens to properly
            // test saving to file storage logic; missing tokens may cause false test passes.
            accountType: AccountType.microsoft,
            microsoftAccountInfo: createMicrosoftAccountInfo(
              microsoftRefreshToken: createExpirableToken(
                value: 'example-microsoft-refresh-token',
              ),
              minecraftAccessToken: createExpirableToken(
                value: 'example-minecraft-access-token',
              ),
            ),
          ),
        ],
        defaultAccountId: 'minecraft-user-id-2',
      );
      return (id, existingAccounts);
    }

    test(
      'preserves defaultAccountId when removing non-default account',
      () async {
        final (id, existingAccounts) = accountIdToRemoveAndExistingAccounts();

        _setInternalState(accounts: existingAccounts);

        await _accountRepository.removeAccount(id);
        final result = _accountRepository.accounts;
        expect(
          result.defaultAccountId,
          existingAccounts.defaultAccountId,
          reason:
              'Should keep defaultAccountId unchanged since the default account was not removed.',
        );

        verifyZeroInteractions(_mockSecureAccountStorage);
      },
    );

    _saveAccountsInFileStorageTests(({
      required bool supportsSecureStorage,
    }) async {
      final (id, existingAccounts) = accountIdToRemoveAndExistingAccounts();

      _setInternalState(
        accounts: existingAccounts,
        supportsSecureStorage: supportsSecureStorage,
      );

      await _accountRepository.removeAccount(id);

      return getExpectedAccountsAfterCall(
        existingAccounts: existingAccounts,
        id: id,
      );
    });

    _setAccountsAndNotifyTests(
      (existingAccounts) async {
        final (id, _) = accountIdToRemoveAndExistingAccounts();

        await _accountRepository.removeAccount(id);

        final expectedAccounts = getExpectedAccountsAfterCall(
          existingAccounts: existingAccounts,
          id: id,
        );
        return (
          expectedAccounts,
          'Should remove the account from the list correctly',
        );
      },
      existingAccountsBuilder: () => accountIdToRemoveAndExistingAccounts().$2,
    );

    test('deletes from secure storage if supported', () async {
      final accounts = MinecraftDummyAccounts.accounts;
      _setInternalState(accounts: accounts, supportsSecureStorage: true);
      final id = accounts.defaultAccountOrThrow.id;

      await _accountRepository.removeAccount(id);
      verify(() => _mockSecureAccountStorage.delete(id)).called(1);
      verifyNoMoreInteractions(_mockSecureAccountStorage);

      verifyZeroInteractions(_mockPlatformSecureStorageSupport);
    });

    test('skips secure storage deletion if unsupported', () async {
      final accounts = MinecraftDummyAccounts.accounts;
      _setInternalState(accounts: accounts, supportsSecureStorage: false);
      final id = accounts.defaultAccountOrThrow.id;

      await _accountRepository.removeAccount(id);
      verifyNever(() => _mockSecureAccountStorage.delete(id));
      verifyNoMoreInteractions(_mockSecureAccountStorage);

      verifyZeroInteractions(_mockPlatformSecureStorageSupport);
    });

    test(
      'sets defaultAccountId to null when the only account is removed',
      () async {
        const id = 'minecraft-user-id';

        final existingAccounts = createMinecraftAccounts(
          list: [createMinecraftAccount(id: id)],
          defaultAccountId: id,
        );

        _setInternalState(accounts: existingAccounts);

        await _accountRepository.removeAccount(id);
        final result = _accountRepository.accounts;
        expect(
          result.defaultAccountId,
          null,
          reason:
              'Should update defaultAccountId to null when the only account is removed',
        );

        final expectedAccounts = existingAccounts.copyWith(
          list: [],
          defaultAccountId: const Wrapped.value(null),
        );
        expect(result, expectedAccounts);
      },
    );

    test(
      'sets defaultAccountId to next account when default account is removed',
      () async {
        const id = 'minecraft-account-id';
        const nextId = 'minecraft-next-account-id';
        final existingAccounts = createMinecraftAccounts(
          list: [
            createMinecraftAccount(id: id),
            createMinecraftAccount(id: nextId),
          ],
          defaultAccountId: id,
        );

        _setInternalState(accounts: existingAccounts);

        await _accountRepository.removeAccount(id);

        final result = _accountRepository.accounts;
        expect(
          result.defaultAccountId,
          isNot(equals(id)),
          reason:
              'Should update defaultAccountId when the default account is removed',
        );
        expect(
          result.defaultAccountId,
          nextId,
          reason: 'Should set defaultAccountId to the next account',
        );
      },
    );

    test(
      'sets defaultAccountId to the previous account when the default account is removed and it is the last account',
      () async {
        const id = 'minecraft-account-id';
        const previousId = 'minecraft-previous-account-id';
        final existingAccounts = createMinecraftAccounts(
          list: [
            createMinecraftAccount(id: previousId),
            createMinecraftAccount(id: id),
          ],
          defaultAccountId: id,
        );

        _setInternalState(accounts: existingAccounts);

        await _accountRepository.removeAccount(id);
        final result = _accountRepository.accounts;
        expect(
          result.defaultAccountId,
          isNot(equals(id)),
          reason:
              'Should update defaultAccountId when the default account is removed',
        );
        expect(
          result.defaultAccountId,
          previousId,
          reason: 'Should set defaultAccountId to the previous account',
        );
      },
    );

    _throwsStateErrorIfAccountsNotLoadedTest(
      () => _accountRepository.updateDefaultAccount(TestConstants.anyString),
    );
  });

  group('updateDefaultAccount', () {
    MinecraftAccounts getExpectedAccountsAfterCall({
      required MinecraftAccounts existingAccounts,
      required String newDefaultAccountId,
    }) => existingAccounts.copyWith(
      defaultAccountId: Wrapped.value(newDefaultAccountId),
    );

    test(
      'does not interact with secure storage even when secure storage is supported',
      () async {
        final existingAccounts = MinecraftDummyAccounts.accounts;
        _setInternalState(
          accounts: existingAccounts,
          supportsSecureStorage: true,
        );

        final id = existingAccounts.list.last.id;

        await _accountRepository.updateDefaultAccount(id);

        verifyZeroInteractions(_mockSecureAccountStorage);
        verifyZeroInteractions(_mockPlatformSecureStorageSupport);
      },
    );

    test('throws $ArgumentError with given ID does not exist', () async {
      _accountRepository.setAccountsForTest(MinecraftAccounts.empty());
      await expectLater(
        _accountRepository.updateDefaultAccount(TestConstants.anyString),
        throwsArgumentError,
      );
    });

    _throwsStateErrorIfAccountsNotLoadedTest(
      () => _accountRepository.updateDefaultAccount(TestConstants.anyString),
    );

    _saveAccountsInFileStorageTests(({
      required bool supportsSecureStorage,
    }) async {
      final existingAccounts = MinecraftDummyAccounts.accounts;
      _setInternalState(
        accounts: existingAccounts,
        supportsSecureStorage: supportsSecureStorage,
      );

      final id = existingAccounts.list.last.id;
      await _accountRepository.updateDefaultAccount(id);
      return getExpectedAccountsAfterCall(
        existingAccounts: existingAccounts,
        newDefaultAccountId: id,
      );
    });

    _setAccountsAndNotifyTests((existingAccounts) async {
      final id = existingAccounts.list.last.id;

      await _accountRepository.updateDefaultAccount(id);
      final expectedAccounts = getExpectedAccountsAfterCall(
        existingAccounts: existingAccounts,
        newDefaultAccountId: id,
      );
      return (expectedAccounts, 'Should only update defaultAccountId');
    }, existingAccountsBuilder: () => MinecraftDummyAccounts.accounts);
  });

  group('accountExists', () {
    test('returns true when account with given ID exists', () {
      final account = MinecraftDummyAccount.account;
      _accountRepository.setAccountsForTest(
        createMinecraftAccounts(list: [account]),
      );
      expect(_accountRepository.accountExists(account.id), true);
    });

    test('returns false when account with given ID does not exist', () {
      _accountRepository.setAccountsForTest(MinecraftDummyAccounts.accounts);
      expect(_accountRepository.accountExists('does-not-exist'), isFalse);
    });

    test('returns false when list is empty', () {
      _accountRepository.setAccountsForTest(MinecraftAccounts.empty());
      expect(_accountRepository.accountExists(TestConstants.anyString), false);
    });
  });

  group('dispose', () {
    test('closes the $StreamController correctly', () async {
      when(
        () => _mockAccountsStreamController.close(),
      ).thenAnswer((_) async => TestConstants.anyString);

      await _accountRepository.dispose();

      verify(() => _mockAccountsStreamController.close()).called(1);
      verifyNoMoreInteractions(_mockAccountsStreamController);
    });
  });
}

void _throwsStateErrorIfAccountsNotLoadedTest(
  Future<void> Function() runActionUnderTest,
) {
  test('throws $StateError when accounts are not loaded yet', () async {
    await expectLater(runActionUnderTest(), throwsStateError);
  });
}

void _setAccountsAndNotifyTests(
  Future<(MinecraftAccounts expectedAccounts, String failureReason)> Function(
    MinecraftAccounts existingAccounts,
  )
  runActionUnderTest, {
  required MinecraftAccounts Function() existingAccountsBuilder,
}) {
  final existingAccounts = existingAccountsBuilder();

  test('sets updated accounts in-memory', () async {
    _setInternalState(accounts: existingAccounts);
    final (expectedAccounts, failureReason) = await runActionUnderTest(
      existingAccounts,
    );

    expect(
      _accountRepository.accounts,
      expectedAccounts,
      reason: failureReason,
    );
  });

  test(
    'adds an event to ${StreamController<MinecraftAccounts>} correctly',
    () async {
      _setInternalState(accounts: existingAccounts);
      final (expectedAccounts, failureReason) = await runActionUnderTest(
        existingAccounts,
      );

      verify(
        () => _mockAccountsStreamController.add(expectedAccounts),
      ).called(1);
      verifyNoMoreInteractions(_mockAccountsStreamController);
    },
  );
}

void _saveAccountsInFileStorageTests(
  Future<MinecraftAccounts> Function({required bool supportsSecureStorage})
  runActionUnderTest,
) {
  Future<void> runTest({required bool secureStorageAvailable}) async {
    final expectedAccounts = await runActionUnderTest(
      supportsSecureStorage: secureStorageAvailable,
    );

    final verificationResult = verify(
      () => _mockFileAccountStorage.saveAccounts(captureAny()),
    );

    final capturedSavedAccounts =
        verificationResult.captured.first as FileAccounts;
    expect(
      capturedSavedAccounts,
      expectedAccounts.toFileDto(storeTokensInFile: !secureStorageAvailable),
    );

    verificationResult.called(1);

    verifyNoMoreInteractions(_mockFileAccountStorage);
  }

  test(
    'saves updated accounts to file storage without tokens when secure storage is available',
    () => runTest(secureStorageAvailable: true),
  );

  test(
    'saves updated accounts to file storage with tokens when secure storage is unavailable',
    () => runTest(secureStorageAvailable: false),
  );
}

void _saveSecureAccountDataTests(
  Future<MinecraftAccount> Function({required bool supportsSecureStorage})
  runActionUnderTest,
  Future<void> Function(MinecraftAccount accountWithNullTokens)
  runActionUnderTestWithNullTokens,
) {
  test('avoids writing to secure storage if unsupported', () async {
    await runActionUnderTest(supportsSecureStorage: false);
    verifyNever(() => _mockSecureAccountStorage.write(any(), any()));
    verifyNoMoreInteractions(_mockSecureAccountStorage);
  });

  test('writes to secure storage if supported', () async {
    final account = await runActionUnderTest(supportsSecureStorage: true);
    final verificationResult = verify(
      () => _mockSecureAccountStorage.write(captureAny(), captureAny()),
    );
    final capturedAccountId = verificationResult.captured.first as String;
    final capturedSecureAccountData =
        verificationResult.captured[1] as SecureAccountData;

    expect(
      capturedAccountId,
      account.id,
      reason: 'Should pass the correct account id to $SecureAccountStorage',
    );

    final microsoftAccountInfo = account.microsoftAccountInfo;
    expect(
      capturedSecureAccountData,
      SecureAccountData(
        microsoftRefreshToken:
            microsoftAccountInfo!.microsoftRefreshToken.value!,
        minecraftAccessToken: microsoftAccountInfo.minecraftAccessToken.value!,
      ),
      reason:
          'Should pass the correct $SecureAccountData to $SecureAccountStorage',
    );

    verificationResult.called(1);

    verifyNoMoreInteractions(_mockSecureAccountStorage);
  });

  test(
    'throws $StateError if tokens in $MinecraftAccount are null when writing $SecureAccountData to secure storage',
    () async {
      final accounts = MinecraftDummyAccounts.accounts;

      _setInternalState(accounts: accounts, supportsSecureStorage: true);

      final accountWithoutTokens = createMinecraftAccount(
        id: accounts.list.first.id,
        accountType: AccountType.microsoft,
        microsoftAccountInfo: createMicrosoftAccountInfo(
          microsoftRefreshToken: createExpirableToken(isValueNull: true),
          minecraftAccessToken: createExpirableToken(isValueNull: true),
        ),
      );
      await expectLater(
        runActionUnderTestWithNullTokens(accountWithoutTokens),
        throwsStateError,
      );

      verifyNever(
        () => _mockSecureAccountStorage.write(captureAny(), captureAny()),
      );
      verifyNoMoreInteractions(_mockSecureAccountStorage);
    },
  );
}

void _defaultAccountIdTests({
  // Whether this is addAccount or updateAccount
  required bool isUpdate,
  required (MinecraftAccount, MinecraftAccounts) Function()
  accountAndExistingAccounts,
  required Future<void> Function(MinecraftAccount account) runActionUnderTest,
}) {
  final (account, existingAccounts) = accountAndExistingAccounts();
  test('retains defaultAccountId when it is already set', () async {
    _setInternalState(accounts: existingAccounts);

    await runActionUnderTest(account);
    final result = _accountRepository.accounts;
    expect(
      result.defaultAccountId,
      existingAccounts.defaultAccountId,
      reason: 'Should keep defaultAccountId unchanged when already set.',
    );
  });

  final updatedOrNew = isUpdate ? 'updated' : 'new';
  test(
    'sets defaultAccountId to $updatedOrNew account when it is initially null',
    () async {
      _setInternalState(
        accounts: existingAccounts.copyWith(
          defaultAccountId: const Wrapped.value(null),
        ),
      );

      await runActionUnderTest(account);
      final result = _accountRepository.accounts;
      expect(
        result.defaultAccountId,
        account.id,
        reason:
            'Should set defaultAccountId to the $updatedOrNew account when initially null.',
      );
    },
  );
}

void _setInternalState({
  required MinecraftAccounts accounts,
  bool? supportsSecureStorage,
}) {
  _accountRepository.setAccountsForTest(accounts);
  _accountRepository.setSecureStorageSupportForTest(
    supported: supportsSecureStorage ?? false,
  );
}

class _MockAccountsStreamController extends Mock
    implements StreamController<MinecraftAccounts> {}

class _MockFileAccountStorage extends Mock implements FileAccountStorage {}

class _MockSecureAccountStorage extends Mock implements SecureAccountStorage {}

class _MockPlatformSecureStorageSupport extends Mock
    implements PlatformSecureStorageSupport {}

// A dummy value of whether the tokens should be stored in the file storage.
// This is an indicator that this value is irrelevant to the test.
const _dummyStoreTokensInFile = false;
