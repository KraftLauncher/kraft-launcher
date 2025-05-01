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

  final MinecraftAccountManager minecraftAccountManager;

  Future<void> loadAccounts() async {
    try {
      final accounts = minecraftAccountManager.loadAccounts();
      emit(
        state.copyWith(
          status: AccountStatus.loadSuccess,
          accounts: accounts,
          selectedIndex: Wrapped.value(accounts.all.isNotEmpty ? 0 : null),
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

  void updateSelectedAccount(int index) =>
      emit(state.copyWith(selectedIndex: Wrapped.value(index)));

  void updateDefaultAccount(int index) {
    emit(
      state.copyWith(
        accounts: minecraftAccountManager.updateDefaultAccount(
          newDefaultAccountIndex: index,
          currentAccounts: state.accounts,
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
        selectedIndex: Wrapped.value(
          _getNewSelectedAccountIndex(
            newAccount: newAccount,
            updatedAccounts: updatedAccounts,
          ),
        ),
        status: accountStatus,
      ),
    );
  }

  int _getNewSelectedAccountIndex({
    // The Minecraft account that was added or modified.
    required MinecraftAccount newAccount,
    required MinecraftAccounts updatedAccounts,
  }) => updatedAccounts.all.indexOf(newAccount);

  void createOfflineAccount({required String username}) {
    final loginResult = minecraftAccountManager.createOfflineAccount(
      username: username,
    );

    emitByAccountResult(
      loginResult,
      accountStatus: AccountStatus.offlineAccountCreated,
    );
  }

  void updateOfflineAccount(int index, {required String username}) {
    final loginResult = minecraftAccountManager.updateOfflineAccount(
      index: index,
      username: username,
    );

    emitByAccountResult(
      loginResult,
      accountStatus: AccountStatus.offlineAccountUpdated,
    );
  }

  void removeAccount(int index) {
    final updatedAccounts = minecraftAccountManager.removeAccount(
      index: index,
      currentMinecraftAccounts: state.accounts,
    );

    emit(
      state.copyWith(
        accounts: updatedAccounts,
        selectedIndex: Wrapped.value(
          updatedAccounts.all.getNewIndexAfterRemoval(index),
        ),
        status: AccountStatus.accountRemoved,
      ),
    );
  }
}
