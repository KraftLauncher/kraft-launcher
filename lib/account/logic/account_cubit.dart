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
            accounts.all.isNotEmpty ? accounts.all.first.id : null,
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
          updatedAccounts.all
              .firstWhere((account) => account.id == newAccount.id)
              .id,
        ),
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
    final removedAccountIndex = state.accounts.all.indexWhere(
      (account) => account.id == accountId,
    );
    final updatedAccounts = minecraftAccountManager.removeAccount(accountId);

    emit(
      state.copyWith(
        accounts: updatedAccounts,
        selectedAccountId: Wrapped.value(
          updatedAccounts.all
              .getReplacementElementAfterRemoval(removedAccountIndex)
              ?.id,
        ),
        status: AccountStatus.accountRemoved,
      ),
    );
  }
}
