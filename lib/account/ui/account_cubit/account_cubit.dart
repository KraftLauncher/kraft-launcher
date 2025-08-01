import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:kraft_launcher/account/logic/account_utils.dart';
import 'package:kraft_launcher/account/logic/launcher_minecraft_account/account_repository.dart';
import 'package:kraft_launcher/account/logic/launcher_minecraft_account/minecraft_account.dart';
import 'package:kraft_launcher/account/logic/launcher_minecraft_account/minecraft_accounts.dart';
import 'package:kraft_launcher/account/logic/offline_account/minecraft_offline_account_factory.dart';
import 'package:kraft_launcher/common/logic/external_stream_cubit.dart';
import 'package:kraft_launcher/common/logic/utils.dart';
import 'package:kraft_launcher/common/ui/utils/exception_with_stacktrace.dart';
import 'package:meta/meta.dart';

part 'account_state.dart';

class AccountCubit extends ExternalStreamCubit<AccountState> {
  AccountCubit({
    required this.offlineAccountFactory,
    required this.accountRepository,
  }) : super(const AccountState()) {
    loadAccounts();
  }

  final AccountRepository accountRepository;
  final MinecraftOfflineAccountFactory offlineAccountFactory;

  Future<void> loadAccounts() async {
    try {
      emit(state.copyWith(status: AccountStatus.loading));
      final accounts = await accountRepository.loadAccounts();
      emit(
        state.copyWith(
          status: AccountStatus.loadSuccess,
          accounts: accounts,
          selectedAccountId: Wrapped.value(
            accounts.list.isNotEmpty ? accounts.list.first.id : null,
          ),
        ),
      );
    } on Exception catch (e, stackTrace) {
      emit(
        state.copyWith(
          exceptionWithStackTrace: ExceptionWithStacktrace(e, stackTrace),
          status: AccountStatus.loadFailure,
        ),
      );
    }
  }

  void updateSelectedAccount(String accountId) =>
      emit(state.copyWith(selectedAccountId: Wrapped.value(accountId)));

  Future<void> updateDefaultAccount(String accountId) async {
    await accountRepository.updateDefaultAccount(accountId);
    emit(state.copyWith(accounts: _accountsFromRepository));
  }

  MinecraftAccounts get _accountsFromRepository => accountRepository.accounts;

  void _addOrUpdateAccountEmit({
    required MinecraftAccount account,
    required AccountStatus? accountStatus,
  }) {
    final updatedAccounts = _accountsFromRepository;
    emit(
      state.copyWith(
        accounts: updatedAccounts,
        selectedAccountId: Wrapped.value(
          updatedAccounts.list.findById(account.id).id,
        ),
        searchedAccounts: _getUpdatedSearchedAccounts(updatedAccounts),
        status: accountStatus,
      ),
    );
  }

  // TODO: Avoid handleExternalAccountChange?, use AccountRepository. This is used in MicrosoftAuthCubit. MicrosoftAuthCubit Should not depend on AccountCubit?

  void handleExternalAccountChange({required MinecraftAccount account}) =>
      _addOrUpdateAccountEmit(account: account, accountStatus: null);

  Future<void> createOfflineAccount({required String username}) async {
    final account = await offlineAccountFactory.createOfflineAccount(
      username: username,
    );
    await accountRepository.addAccount(account);

    _addOrUpdateAccountEmit(
      account: account,
      accountStatus: AccountStatus.offlineAccountCreated,
    );
  }

  Future<void> updateOfflineAccount({
    required String accountId,
    required String username,
  }) async {
    final account = await offlineAccountFactory.updateOfflineAccount(
      existingAccount: _accountsFromRepository.list.findById(accountId),
      username: username,
    );
    await accountRepository.updateAccount(account);

    _addOrUpdateAccountEmit(
      account: account,
      accountStatus: AccountStatus.offlineAccountUpdated,
    );
  }

  Future<void> removeAccount(String accountId) async {
    final removedAccountIndex = state.accounts.list.findIndexById(accountId);

    await accountRepository.removeAccount(accountId);
    final updatedAccounts = _accountsFromRepository;

    emit(
      state.copyWith(
        accounts: updatedAccounts,
        selectedAccountId: Wrapped.value(
          updatedAccounts.list
              .getReplacementElementAfterRemoval(removedAccountIndex)
              ?.id,
        ),
        searchedAccounts: _getUpdatedSearchedAccounts(updatedAccounts),
        status: AccountStatus.accountRemoved,
      ),
    );
  }

  // Returns the updated filtered accounts if the search query is set; used
  // when updating, adding, or removing an account.
  Wrapped<List<MinecraftAccount>?>? _getUpdatedSearchedAccounts(
    MinecraftAccounts updatedAccounts,
  ) =>
      state.searchQuery != null
          ? Wrapped.value(
            updatedAccounts.list.filterByUsername(state.searchQuery!),
          )
          : null;

  void searchAccounts(String searchQuery) {
    if (searchQuery.trim().isEmpty) {
      emit(
        state.copyWith(
          searchedAccounts: const Wrapped.value(null),
          searchQuery: const Wrapped.value(null),
        ),
      );
      return;
    }
    final filteredAccounts = state.accounts.list.filterByUsername(searchQuery);

    emit(
      state.copyWith(
        searchedAccounts: Wrapped.value(filteredAccounts),
        searchQuery: Wrapped.value(searchQuery),
      ),
    );
  }
}
