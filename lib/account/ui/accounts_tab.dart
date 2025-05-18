import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../common/generated/assets.gen.dart';
import '../../common/ui/utils/build_context_ext.dart';
import '../../common/ui/utils/scaffold_messenger_ext.dart';
import '../../common/ui/widgets/info_text_with_lottie.dart';
import '../../common/ui/widgets/search_field.dart';
import '../../common/ui/widgets/split_view.dart';
import '../../common/ui/widgets/unknown_error.dart';
import '../data/minecraft_account.dart';
import '../logic/account_cubit.dart';
import '../logic/account_manager/minecraft_account_manager_exceptions.dart';
import '../logic/microsoft/cubit/microsoft_account_handler_cubit.dart';
import 'account_details.dart';
import 'account_list_tile.dart';
import 'login_with_microsoft_dialog.dart';
import 'upsert_offline_account_dialog.dart';
import 'utils/account_manager_exception_messages.dart';

class AccountsTab extends StatelessWidget {
  const AccountsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountCubit, AccountState>(
      builder: (context, state) {
        if (state.status == AccountStatus.loadFailure) {
          return UnknownError(
            onTryAgain: () => context.read<AccountCubit>().loadAccounts(),
            message: context.loc.unknownErrorWhileLoadingAccounts,
            exceptionWithStackTrace: state.exceptionWithStackTrace!,
          );
        }
        if (state.accounts.all.isEmpty) {
          return const _EmptyAccounts();
        }
        return SplitView(
          primaryPaneTitle: context.loc.accounts,
          primaryPane: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.85,
            child: Column(
              children: [
                // TODO: Add accounts search?
                SearchField(onSubmitted: (a) {}, onChanged: (a) {}),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    itemBuilder: (context, index) {
                      final account = state.accounts.all[index];
                      return Padding(
                        key: ValueKey('${account.id}/$index'),
                        padding: const EdgeInsets.only(top: 8),
                        child: AccountListTile(
                          account: account,
                          key: ValueKey(account.id),
                          isSelected: state.selectedAccountId == account.id,
                        ),
                      );
                    },
                    itemCount: state.accounts.all.length,
                  ),
                ),

                const _AddAccountButton(useFloatingActionButton: true),
              ],
            ),
          ),
          secondaryPane:
              state.selectedAccountId != null
                  ? AccountDetails(account: state.selectedAccountOrThrow)
                  : null,
        );
      },
    );
  }
}

class _AddAccountButton extends StatelessWidget {
  const _AddAccountButton({required this.useFloatingActionButton});

  // Whether to use floating action button or filled button.
  final bool useFloatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: MenuAnchor(
          menuChildren:
              AccountType.values
                  .map(
                    (accountType) => switch (accountType) {
                      AccountType.microsoft => MenuItemButton(
                        leadingIcon: const Icon(Icons.cloud),
                        child: Text(context.loc.microsoft),
                        onPressed: () => LoginWithMicrosoftDialog.show(context),
                      ),

                      AccountType.offline => MenuItemButton(
                        leadingIcon: const Icon(Icons.computer),
                        child: Text(context.loc.offline),
                        onPressed:
                            () => showDialog<void>(
                              context: context,
                              builder:
                                  (context) => const UpsertOfflineAccountDialog(
                                    offlineAccountToUpdate: null,
                                  ),
                            ),
                      ),
                    },
                  )
                  .toList(),
          builder:
              (context, controller, child) => BlocConsumer<
                MicrosoftAccountHandlerCubit,
                MicrosoftAccountHandlerState
              >(
                listener: (context, state) {
                  if (state.microsoftRefreshAccountStatus ==
                      MicrosoftRefreshAccountStatus.success) {
                    context.scaffoldMessenger.showSnackBarText(
                      context.loc.accountRefreshedMessage(
                        state.recentAccountOrThrow.username,
                      ),
                    );
                    context
                        .read<MicrosoftAccountHandlerCubit>()
                        .resetRefreshStatus();
                  }
                  if (state.microsoftRefreshAccountStatus ==
                      MicrosoftRefreshAccountStatus.failure) {
                    final exception = state.exceptionOrThrow;
                    final message = exception.getMessage(context.loc);
                    final scaffoldMessenger = context.scaffoldMessenger;

                    // Handle special errors

                    switch (exception) {
                      case MicrosoftRefreshTokenExpiredAccountManagerException():
                        scaffoldMessenger.showSnackBarText(
                          context.loc.sessionExpired,
                          snackBarAction: SnackBarAction(
                            label: context.loc.signInWithMicrosoft,
                            onPressed:
                                () => LoginWithMicrosoftDialog.show(context),
                          ),
                        );
                      case MicrosoftExpiredOrUnauthorizedRefreshTokenAccountManagerException():
                        scaffoldMessenger.showSnackBarText(
                          context.loc.sessionExpiredOrAccessRevoked,
                          snackBarAction: SnackBarAction(
                            label: context.loc.signInWithMicrosoft,
                            onPressed:
                                () => LoginWithMicrosoftDialog.show(context),
                          ),
                        );
                      case _:
                        scaffoldMessenger.showSnackBarText(message);
                    }

                    context
                        .read<MicrosoftAccountHandlerCubit>()
                        .resetRefreshStatus();
                  }
                },
                builder: (context, state) {
                  final isRefreshingAccount =
                      state.microsoftRefreshAccountStatus ==
                      MicrosoftRefreshAccountStatus.loading;
                  final onPressed =
                      isRefreshingAccount
                          ? null
                          : () {
                            final isAlreadyLoggingIn =
                                state.microsoftLoginStatus ==
                                MicrosoftLoginStatus.loading;
                            if (isAlreadyLoggingIn) {
                              context.scaffoldMessenger.showSnackBarText(
                                context.loc.waitForOngoingTask,
                              );
                              return;
                            }
                            controller.isOpen
                                ? controller.close()
                                : controller.open();
                          };
                  final label = Text(context.loc.addAccount);
                  const icon = Icon(Icons.add);
                  if (useFloatingActionButton) {
                    return FloatingActionButton.extended(
                      onPressed: onPressed,
                      label: label,
                      icon: icon,
                      tooltip: context.loc.addAccount,
                    );
                  }
                  return FilledButton.icon(
                    onPressed: onPressed,
                    label: label,
                    icon: icon,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32.0,
                        vertical: 16.0,
                      ),
                      textStyle: const TextStyle(fontSize: 18.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  );
                },
              ),
        ),
      ),
    );
  }
}

class _EmptyAccounts extends StatelessWidget {
  const _EmptyAccounts();

  @override
  Widget build(BuildContext context) {
    return InfoTextWithLottie(
      title: context.loc.accountsEmptyTitle,
      subtitle: context.loc.accountsEmptySubtitle,
      lottieAssetPath: Assets.lottie.noDataFound.noDataCoffee.path,
      bellowSubtitle: const _AddAccountButton(useFloatingActionButton: false),
    );
  }
}
