import 'dart:async';

import 'package:meta/meta.dart';

import '../../common/logic/app_logger.dart';
import '../../common/logic/utils.dart';
import '../data/minecraft_account/local_file_storage/file_account.dart';
import '../data/minecraft_account/local_file_storage/file_account_storage.dart';
import '../data/minecraft_account/local_file_storage/file_accounts.dart';
import '../data/minecraft_account/mappers/accounts_to_file_accounts_mapper.dart';
import '../data/minecraft_account/mappers/file_accounts_to_accounts_mapper.dart';
import '../data/minecraft_account/minecraft_account.dart';
import '../data/minecraft_account/minecraft_accounts.dart';
import '../data/minecraft_account/secure_storage/secure_account_data.dart';
import '../data/minecraft_account/secure_storage/secure_account_storage.dart';
import 'account_utils.dart';
import 'platform_secure_storage_support.dart';

// TODO: Write tests, update AccountManager tests

class AccountRepository {
  AccountRepository({
    required this.fileAccountStorage,
    required this.secureAccountStorage,
    required this.secureStorageSupport,
    @visibleForTesting StreamController<MinecraftAccounts>? accountsController,
  }) : _accountsController = accountsController ?? StreamController.broadcast();

  @visibleForTesting
  final FileAccountStorage fileAccountStorage;
  @visibleForTesting
  final SecureAccountStorage secureAccountStorage;
  @visibleForTesting
  final PlatformSecureStorageSupport secureStorageSupport;

  bool? _supportsSecureStorage;
  bool get _requireSupportsSecureStorage =>
      _supportsSecureStorage ??
      (throw StateError(
        '$AccountRepository.loadAccounts() must be called before accessing supportsSecureStorage.',
      ));

  @visibleForTesting
  bool get supportsSecureStorage => _requireSupportsSecureStorage;

  @visibleForTesting
  void setSecureStorageSupportForTest({required bool supported}) {
    _supportsSecureStorage = supported;
  }

  // TODO: We might not use this approach or might not use Stream at all? Also see https://pub.dev/documentation/rxdart/latest/rx/BehaviorSubject-class.html
  final StreamController<MinecraftAccounts> _accountsController;
  Stream<MinecraftAccounts> get accountsStream => _accountsController.stream;

  MinecraftAccounts? _accounts;

  MinecraftAccounts get _requireAccounts =>
      _accounts ??
      (throw StateError(
        '$AccountRepository.loadAccounts() must be called before accessing accounts.',
      ));

  MinecraftAccounts get accounts =>
      _requireAccounts.copyWith(list: List.unmodifiable(_requireAccounts.list));

  @visibleForTesting
  void setAccountsForTest(MinecraftAccounts accounts) {
    _accounts = accounts;
  }

  void _setAccountsAndNotify(MinecraftAccounts accounts) {
    _accounts = accounts;
    _accountsController.add(accounts);
  }

  Future<void> _saveAccountsInFileStorage(MinecraftAccounts accounts) async {
    await fileAccountStorage.saveAccounts(
      accounts.toFileAccounts(
        storeTokensInFile: !_requireSupportsSecureStorage,
      ),
    );
  }

  Future<void> _saveSecureAccountData(MinecraftAccount account) async {
    if (!_requireSupportsSecureStorage) {
      return;
    }
    final microsoftAccountInfo = account.microsoftAccountInfo;
    if (microsoftAccountInfo != null) {
      await secureAccountStorage.write(
        account.id,
        SecureAccountData(
          microsoftRefreshToken:
              microsoftAccountInfo.microsoftOAuthRefreshToken.value ??
              (throw StateError(
                'The Microsoft refresh token should not be null to save it in secure storage',
              )),
          minecraftAccessToken:
              microsoftAccountInfo.minecraftAccessToken.value ??
              (throw StateError(
                'The Minecraft access token should not be null to save it in secure storage',
              )),
        ),
      );
    }
  }

  Future<MinecraftAccounts> loadAccounts() async {
    Future<MinecraftAccounts> initializeEmptyAccounts() async {
      final accounts = MinecraftAccounts.empty();
      await _saveAccountsInFileStorage(accounts);

      return accounts;
    }

    MicrosoftReauthRequiredReason? getReauthRequiredReason(
      FileAccount account, {
      required bool? accountTokensMissingFromSecureStorage,
      required bool? accountTokensMissingFromFileStorage,
    }) {
      final microsoftAccountInfo = account.microsoftAccountInfo;
      if (microsoftAccountInfo == null) {
        return null;
      }
      if (microsoftAccountInfo.accessRevoked) {
        return MicrosoftReauthRequiredReason.accessRevoked;
      }
      if (microsoftAccountInfo
          .microsoftOAuthRefreshToken
          .expiresAt
          .hasExpired) {
        return MicrosoftReauthRequiredReason.refreshTokenExpired;
      }
      if (accountTokensMissingFromSecureStorage ?? false) {
        return MicrosoftReauthRequiredReason.tokensMissingFromSecureStorage;
      }
      if (accountTokensMissingFromFileStorage ?? false) {
        return MicrosoftReauthRequiredReason.tokensMissingFromFileStorage;
      }
      return null;
    }

    Future<MinecraftAccounts> mapFileAccountsToAccounts(
      FileAccounts fileAccounts,
    ) async {
      // TODO: Migrate tokens when switching between account and file storage
      if (_requireSupportsSecureStorage) {
        return fileAccounts.mapToAccountsAsync((fileAccount) async {
          if (fileAccount.accountType == AccountType.offline) {
            return fileAccount.toAccount(
              secureAccountData: null,
              microsoftReauthRequiredReason: null,
            );
          }
          final data = await secureAccountStorage.read(fileAccount.id);
          if (data != null) {
            return fileAccount.toAccount(
              secureAccountData: data,
              microsoftReauthRequiredReason: getReauthRequiredReason(
                fileAccount,
                accountTokensMissingFromSecureStorage: false,
                accountTokensMissingFromFileStorage: null,
              ),
            );
          }

          final account = fileAccount.toAccount(
            // The user needs to re-authenticate
            secureAccountData: null,
            microsoftReauthRequiredReason: getReauthRequiredReason(
              fileAccount,
              accountTokensMissingFromSecureStorage: true,
              accountTokensMissingFromFileStorage: null,
            ),
          );

          return account;
        });
      }
      return fileAccounts.toAccounts(
        microsoftReauthRequiredReason:
            (account) => getReauthRequiredReason(
              account,
              accountTokensMissingFromSecureStorage: null,
              accountTokensMissingFromFileStorage:
                  account.microsoftAccountInfo?.hasMissingTokens ?? false,
            ),
      );
    }

    _supportsSecureStorage = await secureStorageSupport.isSupported();
    if (!_requireSupportsSecureStorage) {
      AppLogger.i(
        'Secure storage is not available on this platform. Falling back to file storage.',
      );
    }

    final fileAccounts = await fileAccountStorage.readAccounts();

    final accounts =
        fileAccounts != null
            ? await mapFileAccountsToAccounts(fileAccounts)
            : (await initializeEmptyAccounts());

    final accountsWithUnmodifiableList = accounts.copyWith(
      list: List.unmodifiable(accounts.list),
    );

    _setAccountsAndNotify(accountsWithUnmodifiableList);

    return accountsWithUnmodifiableList;
  }

  Future<void> addAccount(MinecraftAccount newAccount) async {
    final existingAccounts = _requireAccounts;

    final updatedAccountsList = List<MinecraftAccount>.unmodifiable([
      newAccount,
      ...existingAccounts.list,
    ]);

    final currentDefaultAccountId = existingAccounts.defaultAccountId;
    final updatedAccounts = existingAccounts.copyWith(
      list: updatedAccountsList,
      defaultAccountId: Wrapped.value(
        currentDefaultAccountId != null
            ? updatedAccountsList
                .firstWhere((account) => currentDefaultAccountId == account.id)
                .id
            : newAccount.id,
      ),
    );

    await _saveAccountsInFileStorage(updatedAccounts);
    await _saveSecureAccountData(newAccount);

    _setAccountsAndNotify(updatedAccounts);
  }

  Future<void> updateAccount(MinecraftAccount accountToUpdate) async {
    final existingAccounts = _requireAccounts;
    final updatedAccounts = existingAccounts
        .updateById(accountToUpdate.id, (_) => accountToUpdate)
        .copyWith(
          defaultAccountId: Wrapped.value(
            existingAccounts.defaultAccountId ?? accountToUpdate.id,
          ),
        );

    await _saveAccountsInFileStorage(updatedAccounts);
    await _saveSecureAccountData(accountToUpdate);

    _setAccountsAndNotify(updatedAccounts);
  }

  Future<void> removeAccount(String accountId) async {
    final existingAccounts = _requireAccounts;

    final existingAccountIndex = existingAccounts.list.accountIndexById(
      accountId,
    );

    final updatedAccountsList = List<MinecraftAccount>.unmodifiable(
      List.from(existingAccounts.list)..removeAt(existingAccountIndex),
    );
    final updatedAccounts = existingAccounts.copyWith(
      list: updatedAccountsList,
      defaultAccountId: Wrapped.value(
        updatedAccountsList
            .getReplacementElementAfterRemoval(existingAccountIndex)
            ?.id,
      ),
    );

    await _saveAccountsInFileStorage(updatedAccounts);
    if (_requireSupportsSecureStorage) {
      await secureAccountStorage.delete(accountId);
    }

    _setAccountsAndNotify(updatedAccounts);
  }

  Future<void> updateDefaultAccount(String accountId) async {
    final existingAccounts = _requireAccounts;
    final updatedAccounts = existingAccounts.copyWith(
      defaultAccountId: Wrapped.value(accountId),
    );

    await _saveAccountsInFileStorage(updatedAccounts);

    _setAccountsAndNotify(updatedAccounts);
  }

  // TODO: Add upsertAccount for easier testing? Update MinecraftAccountManager and all usages of addAccount, updateAccount to use it if done
  bool accountExists(String accountId) =>
      _requireAccounts.list.any((account) => account.id == accountId);
}
