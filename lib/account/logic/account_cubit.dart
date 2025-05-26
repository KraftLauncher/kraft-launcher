import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../common/logic/utils.dart';
import '../../common/ui/utils/exception_with_stacktrace.dart';
import '../data/minecraft_account.dart';
import '../data/minecraft_accounts.dart';
import 'account_manager/minecraft_account_manager.dart';
import 'account_manager/minecraft_account_manager_exceptions.dart';

part 'account_state.dart';

class AccountCubit extends Cubit<AccountState> {
  AccountCubit({required this.minecraftAccountManager})
    : super(const AccountState()) {
    loadAccounts();
  }

  @visibleForTesting
  final MinecraftAccountManager minecraftAccountManager;

  Future<void> loadAccounts() async {
    try {
      final accounts = minecraftAccountManager.loadAccounts();
      emit(
        state.copyWith(
          status: AccountStatus.loadSuccess,
          accounts: accounts,
          selectedAccountId: Wrapped.value(
            accounts.list.isNotEmpty ? accounts.list.first.id : null,
          ),
        ),
      );
    } on AccountManagerException catch (e, stackTrace) {
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

  void updateDefaultAccount(String accountId) {
    emit(
      state.copyWith(
        accounts: minecraftAccountManager.updateDefaultAccount(
          newDefaultAccountId: accountId,
        ),
      ),
    );
  }

  void emitByAccountResult(
    AccountResult loginResult, {
    AccountStatus? accountStatus,
  }) {
    final (newAccount, updatedAccounts) = (
      loginResult.newAccount,
      loginResult.updatedAccounts,
    );

    emit(
      state.copyWith(
        accounts: updatedAccounts,
        selectedAccountId: Wrapped.value(
          updatedAccounts.list
              .firstWhere((account) => account.id == newAccount.id)
              .id,
        ),
        searchedAccounts: _getUpdatedSearchedAccounts(updatedAccounts),
        status: accountStatus,
      ),
    );
  }

  void setAccounts(MinecraftAccounts accounts) {
    emit(state.copyWith(accounts: accounts));
  }

  void createOfflineAccount({required String username}) {
    final loginResult = minecraftAccountManager.createOfflineAccount(
      username: username,
    );

    emitByAccountResult(
      loginResult,
      accountStatus: AccountStatus.offlineAccountCreated,
    );
  }

  void updateOfflineAccount({
    required String accountId,
    required String username,
  }) {
    final loginResult = minecraftAccountManager.updateOfflineAccount(
      accountId: accountId,
      username: username,
    );

    emitByAccountResult(
      loginResult,
      accountStatus: AccountStatus.offlineAccountUpdated,
    );
  }

  void removeAccount(String accountId) {
    final removedAccountIndex = state.accounts.list.indexWhere(
      (account) => account.id == accountId,
    );
    final updatedAccounts = minecraftAccountManager.removeAccount(accountId);

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

  // Returns the updated filtered accounts if the search query is set; used when updating, adding, or removing an account.
  Wrapped<List<MinecraftAccount>?>? _getUpdatedSearchedAccounts(
    MinecraftAccounts updatedAccounts,
  ) =>
      state.searchQuery != null
          ? Wrapped.value(
            _filterAccountsByUsername(
              state.searchQuery!,
              accounts: updatedAccounts.list,
            ),
          )
          : null;

  List<MinecraftAccount> _filterAccountsByUsername(
    String searchQuery, {
    required List<MinecraftAccount> accounts,
  }) {
    final filteredAccounts =
        accounts
            .where(
              (account) => account.username.trim().toLowerCase().contains(
                searchQuery.trim().toLowerCase(),
              ),
            )
            .toList();
    return filteredAccounts;
  }

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
    final filteredAccounts = _filterAccountsByUsername(
      searchQuery,
      accounts: state.accounts.list,
    );

    emit(
      state.copyWith(
        searchedAccounts: Wrapped.value(filteredAccounts),
        searchQuery: Wrapped.value(searchQuery),
      ),
    );
  }
}
