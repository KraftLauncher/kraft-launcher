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
    this.selectedAccountId,
    this.accounts = const MinecraftAccounts(all: [], defaultAccountId: null),
    this.searchedAccounts,
    this.searchQuery,
    this.status = AccountStatus.initial,
    this.exceptionWithStackTrace,
  });

  // The selected account in the accounts tab, pressing an account list tile
  // will updates the selected index.
  final String? selectedAccountId;

  String? get selectedAccountIdOrThrow =>
      selectedAccountId ??
      (throw Exception(
        'Expected the current selected Minecraft account to be not null',
      ));

  MinecraftAccount get selectedAccountOrThrow => accounts.all.firstWhere(
    (account) => account.id == selectedAccountIdOrThrow,
  );

  final MinecraftAccounts accounts;

  final List<MinecraftAccount>? searchedAccounts;
  final String? searchQuery;

  List<MinecraftAccount> get displayAccounts =>
      searchedAccounts != null ? searchedAccounts! : accounts.all;

  final AccountStatus status;

  // There are no specific errors that could be encountered with this state.
  final ExceptionWithStacktrace<AccountManagerException>?
  exceptionWithStackTrace;

  @override
  List<Object?> get props => [
    selectedAccountId,
    accounts,
    searchedAccounts,
    searchQuery,
    status,
    exceptionWithStackTrace,
  ];

  AccountState copyWith({
    Wrapped<String?>? selectedAccountId,
    MinecraftAccounts? accounts,
    Wrapped<List<MinecraftAccount>?>? searchedAccounts,
    Wrapped<String?>? searchQuery,
    AccountStatus? status,
    ExceptionWithStacktrace<AccountManagerException>? exceptionWithStackTrace,
  }) => AccountState(
    selectedAccountId:
        selectedAccountId != null
            ? selectedAccountId.value
            : this.selectedAccountId,
    accounts: accounts ?? this.accounts,
    searchedAccounts:
        searchedAccounts != null
            ? searchedAccounts.value
            : this.searchedAccounts,
    searchQuery: searchQuery != null ? searchQuery.value : this.searchQuery,
    status: status ?? this.status,
    exceptionWithStackTrace:
        exceptionWithStackTrace ?? this.exceptionWithStackTrace,
  );
}
