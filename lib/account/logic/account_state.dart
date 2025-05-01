part of 'account_cubit.dart';

enum AccountStatus {
  initial,
  loadSuccess,
  loadFailure,
  offlineAccountCreated,
  offlineAccountUpdated,
  // Removing Microsoft or offline account.
  accountRemoved,
}

@immutable
final class AccountState extends Equatable {
  const AccountState({
    this.selectedIndex,
    this.accounts = const MinecraftAccounts(all: [], defaultAccountIndex: null),
    this.status = AccountStatus.initial,
    this.exceptionWithStackTrace,
  });

  // The selected account in the accounts tab, pressing an account list tile
  // will updates the selected index.
  final int? selectedIndex;

  final MinecraftAccounts accounts;

  final AccountStatus status;

  // There are no specific errors that could be encountered with this state.
  final ExceptionWithStacktrace<AccountManagerException>?
  exceptionWithStackTrace;

  @override
  List<Object?> get props => [
    selectedIndex,
    accounts,
    status,
    exceptionWithStackTrace,
  ];

  AccountState copyWith({
    Wrapped<int?>? selectedIndex,
    MinecraftAccounts? accounts,
    AccountStatus? status,
    ExceptionWithStacktrace<AccountManagerException>? exceptionWithStackTrace,
  }) => AccountState(
    selectedIndex:
        selectedIndex != null ? selectedIndex.value : this.selectedIndex,
    accounts: accounts ?? this.accounts,
    status: status ?? this.status,
    exceptionWithStackTrace:
        exceptionWithStackTrace ?? this.exceptionWithStackTrace,
  );
}
