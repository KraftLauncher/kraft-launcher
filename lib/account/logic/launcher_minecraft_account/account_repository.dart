import 'dart:async';

import 'package:kraft_launcher/account/data/launcher_minecraft_account/local_file_storage/file_account_storage.dart';
import 'package:kraft_launcher/account/data/launcher_minecraft_account/local_file_storage/file_minecraft_account.dart';
import 'package:kraft_launcher/account/data/launcher_minecraft_account/local_file_storage/file_minecraft_accounts.dart';
import 'package:kraft_launcher/account/data/launcher_minecraft_account/local_file_storage/mappers/accounts_mapper.dart';
import 'package:kraft_launcher/account/data/launcher_minecraft_account/local_file_storage/mappers/file_accounts_mapper.dart';
import 'package:kraft_launcher/account/data/launcher_minecraft_account/secure_storage/secure_account_data.dart';
import 'package:kraft_launcher/account/data/launcher_minecraft_account/secure_storage/secure_account_storage.dart';
import 'package:kraft_launcher/account/logic/account_utils.dart';
import 'package:kraft_launcher/account/logic/launcher_minecraft_account/minecraft_account.dart';
import 'package:kraft_launcher/account/logic/launcher_minecraft_account/minecraft_accounts.dart';
import 'package:kraft_launcher/account/logic/platform_secure_storage_support.dart';
import 'package:kraft_launcher/common/logic/app_logger.dart';
import 'package:kraft_launcher/common/logic/utils.dart';
import 'package:meta/meta.dart';

@visibleForTesting
typedef AccountsStreamControllerFactory = StreamController<MinecraftAccounts>;

/// Manages storage and retrieval of Minecraft accounts
/// locally within the app on this device. See also: [MinecraftAccount].
///
/// Handles account data storage and retrieval, combining both file and secure storage
/// for account info.
///
/// Interacts with the following storage layers to meet the requirements:
///
/// * [FileAccountStorage] for file-based storage. Stores account information,
///   except for the account tokens, which are stored in system secure storage when supported.
///   If secure storage is not available, the tokens will be stored in file storage.
///
/// * [SecureAccountStorage] for secure storage (if supported). Secure storage support
///   is platform-dependent, so [PlatformSecureStorageSupport] is used to check
///   if [SecureAccountStorage] can be used.
///
/// Provides a single source of truth for the account data, ensuring a consistent state across the app.
///
/// **Note:** [loadAccounts] must be called before invoking any other operations to avoid a [StateError]:
///
/// ```dart
/// final repository = AccountRepository(...);
/// await repository.loadAccounts();
///
/// await repository.addAccount(...);
/// await repository.removeAccount(...);
/// ```
class AccountRepository {
  // TODO: Rename to AccountsRepository to be consistent with MinecraftVersionsRepository? Also FileAccountStorage and SecureAccountStorage and other possible usages.
  AccountRepository({
    required this.fileAccountStorage,
    required this.secureAccountStorage,
    required this.secureStorageSupport,
    @visibleForTesting
    AccountsStreamControllerFactory? accountsStreamControllerFactory,
  }) : _accountsController =
           accountsStreamControllerFactory ?? StreamController.broadcast();

  @visibleForTesting
  final FileAccountStorage fileAccountStorage;
  @visibleForTesting
  final SecureAccountStorage secureAccountStorage;
  @visibleForTesting
  final PlatformSecureStorageSupport secureStorageSupport;

  bool? _supportsSecureStorage;

  @visibleForTesting
  bool get supportsSecureStorageOrThrow =>
      _supportsSecureStorage ??
      (throw StateError(
        '$AccountRepository.loadAccounts() must be called before accessing supportsSecureStorage.',
      ));

  @visibleForTesting
  void setSecureStorageSupportForTest({required bool supported}) {
    _supportsSecureStorage = supported;
  }

  // TODO: We might not use this approach or might not use Stream at all? See also: https://pub.dev/documentation/rxdart/latest/rx/BehaviorSubject-class.html
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

  void _setAccountsAndNotify(MinecraftAccounts updatedAccounts) {
    _accounts = updatedAccounts;
    _accountsController.add(updatedAccounts);
  }

  Future<void> _saveAccountsInFileStorage(
    MinecraftAccounts updatedAccounts,
  ) async {
    await fileAccountStorage.saveAccounts(
      updatedAccounts.toFileDto(
        storeTokensInFile: !supportsSecureStorageOrThrow,
      ),
    );
  }

  Future<void> _saveSecureAccountData(MinecraftAccount account) async {
    if (!supportsSecureStorageOrThrow) {
      return;
    }
    final microsoftAccountInfo = account.microsoftAccountInfo;
    if (microsoftAccountInfo != null) {
      await secureAccountStorage.write(
        account.id,
        SecureAccountData(
          microsoftRefreshToken:
              microsoftAccountInfo.microsoftRefreshToken.value ??
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
    MinecraftAccounts initializeEmptyAccounts() {
      final accounts = MinecraftAccounts.empty();
      return accounts;
    }

    Future<MinecraftAccounts> mapFileAccountsToAccounts(
      FileMinecraftAccounts fileAccounts,
    ) async {
      MicrosoftReauthRequiredReason? getReauthRequiredReason(
        FileMinecraftAccount account, {
        bool? accountTokensMissingFromSecureStorage,
        bool? accountTokensMissingFromFileStorage,
      }) {
        final microsoftAccountInfo = account.microsoftAccountInfo;
        if (microsoftAccountInfo == null) {
          return null;
        }

        if (microsoftAccountInfo.accessRevoked) {
          return MicrosoftReauthRequiredReason.accessRevoked;
        }
        if (microsoftAccountInfo.microsoftRefreshToken.expiresAt.hasExpired) {
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

      // Currently, this doesn't migrate tokens when they are found in
      // file but not in secure storage (and it's supported), or vice versa.
      // This isn't needed at the moment.

      if (supportsSecureStorageOrThrow) {
        return fileAccounts.mapToAppAsync((fileAccount) async {
          return switch (fileAccount.accountType) {
            AccountType.microsoft => await () async {
              final data = await secureAccountStorage.read(fileAccount.id);
              if (data != null) {
                return fileAccount.toApp(
                  secureAccountData: data,
                  microsoftReauthRequiredReason: getReauthRequiredReason(
                    fileAccount,
                    accountTokensMissingFromSecureStorage: false,
                  ),
                );
              }

              final account = fileAccount.toApp(
                // The user needs to re-authenticate
                secureAccountData: null,
                microsoftReauthRequiredReason: getReauthRequiredReason(
                  fileAccount,
                  accountTokensMissingFromSecureStorage: true,
                ),
              );

              return account;
            }(),
            AccountType.offline => fileAccount.toApp(
              secureAccountData: null,
              microsoftReauthRequiredReason: null,
            ),
          };
        });
      }
      return fileAccounts.toApp(
        resolveMicrosoftReauthReason:
            (account) => getReauthRequiredReason(
              account,
              accountTokensMissingFromFileStorage:
                  account.microsoftAccountInfo?.hasMissingTokens ?? false,
            ),
      );
    }

    _supportsSecureStorage = await secureStorageSupport.isSupported();
    if (!supportsSecureStorageOrThrow) {
      AppLogger.i(
        'Secure storage is not available on this platform. Falling back to file storage.',
      );
    }

    final fileAccounts = await fileAccountStorage.readAccounts();

    final accounts =
        fileAccounts != null
            ? await mapFileAccountsToAccounts(fileAccounts)
            : initializeEmptyAccounts();

    final accountsWithUnmodifiableList = accounts.copyWith(
      list: List.unmodifiable(accounts.list),
    );

    _setAccountsAndNotify(accountsWithUnmodifiableList);

    return accountsWithUnmodifiableList;
  }

  Future<void> addAccount(MinecraftAccount newAccount) async {
    await _modifyAndSaveAccount(
      account: newAccount,
      buildList: (existingAccounts) => [newAccount, ...existingAccounts.list],
    );
  }

  Future<void> updateAccount(MinecraftAccount updatedAccount) async {
    await _modifyAndSaveAccount(
      account: updatedAccount,
      buildList:
          (existingAccounts) => existingAccounts.list.updateById(
            updatedAccount.id,
            (_) => updatedAccount,
          ),
    );
  }

  // Shared for both [addAccount] and [updateAccount].
  Future<void> _modifyAndSaveAccount({
    required MinecraftAccount account,
    required List<MinecraftAccount> Function(MinecraftAccounts existingAccounts)
    buildList,
  }) async {
    final existingAccounts = _requireAccounts;

    final updatedAccounts = existingAccounts.copyWith(
      list: buildList(existingAccounts),
      defaultAccountId: Wrapped.value(
        existingAccounts.defaultAccountId ?? account.id,
      ),
    );

    await _saveAccountsInFileStorage(updatedAccounts);
    await _saveSecureAccountData(account);

    _setAccountsAndNotify(updatedAccounts);
  }

  Future<void> removeAccount(String accountId) async {
    final existingAccounts = _requireAccounts;

    final existingAccountIndex = existingAccounts.list.findIndexById(accountId);

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
    if (supportsSecureStorageOrThrow) {
      await secureAccountStorage.delete(accountId);
    }

    _setAccountsAndNotify(updatedAccounts);
  }

  Future<void> updateDefaultAccount(String accountId) async {
    if (!accountExists(accountId)) {
      throw ArgumentError.value(
        accountId,
        'accountId',
        'Account ID not found in current account list.',
      );
    }
    final updatedAccounts = _requireAccounts.copyWith(
      defaultAccountId: Wrapped.value(accountId),
    );

    await _saveAccountsInFileStorage(updatedAccounts);

    _setAccountsAndNotify(updatedAccounts);
  }

  bool accountExists(String accountId) =>
      _requireAccounts.list.any((account) => account.id == accountId);

  Future<void> dispose() async {
    await _accountsController.close();
  }
}
