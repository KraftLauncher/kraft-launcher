import 'dart:async';

import 'package:kraft_launcher/account/data/minecraft_account/local_file_storage/file_account_storage.dart';
import 'package:kraft_launcher/account/data/minecraft_account/minecraft_accounts.dart';
import 'package:kraft_launcher/account/data/minecraft_account/secure_storage/secure_account_storage.dart';
import 'package:kraft_launcher/account/logic/account_repository.dart';
import 'package:kraft_launcher/account/logic/platform_secure_storage_support.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../data/minecraft_account_utils.dart';
import '../data/minecraft_dummy_accounts.dart';

// TODO: Complete full unit tests

void main() {
  late AccountRepository accountRepository;
  late _MockAccountsStreamController mockAccountsStreamController;

  late _MockFileAccountStorage mockFileAccountStorage;
  late _MockSecureAccountStorage mockSecureAccountStorage;
  late _MockPlatformSecureStorageSupport mockPlatformSecureStorageSupport;

  setUp(() {
    mockAccountsStreamController = _MockAccountsStreamController();
    mockFileAccountStorage = _MockFileAccountStorage();
    mockSecureAccountStorage = _MockSecureAccountStorage();
    mockPlatformSecureStorageSupport = _MockPlatformSecureStorageSupport();
    accountRepository = AccountRepository(
      fileAccountStorage: mockFileAccountStorage,
      secureAccountStorage: mockSecureAccountStorage,
      secureStorageSupport: mockPlatformSecureStorageSupport,
      accountsController: mockAccountsStreamController,
    );
  });

  group('accountsStream', () {
    test('uses $StreamController.broadcast by default', () {
      expect(
        AccountRepository(
          fileAccountStorage: mockFileAccountStorage,
          secureAccountStorage: mockSecureAccountStorage,
          secureStorageSupport: mockPlatformSecureStorageSupport,
          accountsController: null,
        ).accountsStream.isBroadcast,
        true,
      );
    });

    test('reflects current internal state', () {
      final stream = Stream<MinecraftAccounts>.value(
        MinecraftDummyAccounts.accounts,
      );
      when(() => mockAccountsStreamController.stream).thenAnswer((_) => stream);
      expect(accountRepository.accountsStream, same(stream));
    });
  });

  group('supportsSecureStorage', () {
    test('throws $StateError when not initialized', () {
      expect(() => accountRepository.supportsSecureStorage, throwsStateError);
    });

    test('reflects current internal state', () {
      for (final value in {true, false}) {
        accountRepository.setSecureStorageSupportForTest(supported: value);

        final secureStorageSupported = accountRepository.supportsSecureStorage;
        expect(accountRepository.supportsSecureStorage, secureStorageSupported);
      }
    });
  });

  group('accounts', () {
    test('throws $StateError when not initialized', () {
      expect(() => accountRepository.accounts, throwsStateError);
    });

    test('list is unmodifiable', () {
      accountRepository.setAccountsForTest(MinecraftAccounts.empty());
      expect(
        () => accountRepository.accounts.list.add(createMinecraftAccount()),
        throwsUnsupportedError,
      );
    });

    test('reflects current internal state', () {
      final accounts = MinecraftDummyAccounts.accounts;
      accountRepository.setAccountsForTest(accounts);

      expect(accountRepository.accounts, equals(accounts));
      expect(
        accountRepository.accounts,
        isNot(same(accounts)),
        reason:
            'Should return a copy of $MinecraftAccounts but not the same internal instance',
      );
    });
  });

  group('accountExists', () {
    test('returns true when account with given ID exists', () {
      final account = MinecraftDummyAccount.account;
      accountRepository.setAccountsForTest(
        createMinecraftAccounts(list: [account]),
      );
      expect(accountRepository.accountExists(account.id), true);
    });

    test('returns false when account with given ID does not exist', () {
      accountRepository.setAccountsForTest(MinecraftDummyAccounts.accounts);
      expect(accountRepository.accountExists('does-not-exist'), isFalse);
    });

    test('returns false when list is empty', () {
      accountRepository.setAccountsForTest(MinecraftAccounts.empty());
      expect(accountRepository.accountExists('any'), false);
    });
  });
}

class _MockAccountsStreamController extends Mock
    implements StreamController<MinecraftAccounts> {}

class _MockFileAccountStorage extends Mock implements FileAccountStorage {}

class _MockSecureAccountStorage extends Mock implements SecureAccountStorage {}

class _MockPlatformSecureStorageSupport extends Mock
    implements PlatformSecureStorageSupport {}
