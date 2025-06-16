import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../common/generated/assets.gen.dart';
import '../../common/ui/utils/build_context_ext.dart';
import '../../common/ui/utils/scaffold_messenger_ext.dart';
import '../../common/ui/widgets/info_text_with_lottie.dart';
import '../../common/ui/widgets/search_field.dart';
import '../../common/ui/widgets/split_view.dart';
import '../../common/ui/widgets/unknown_error.dart';
import '../data/minecraft_account/minecraft_account.dart';
import '../logic/account_cubit/account_cubit.dart';
import '../logic/microsoft/cubit/microsoft_account_handler_cubit.dart';
import '../logic/microsoft/minecraft/account_refresher/minecraft_account_refresher_exceptions.dart'
    as minecraft_account_refresher_exceptions;
import '../logic/microsoft/minecraft/account_service/minecraft_account_service_exceptions.dart'
    as minecraft_account_service_exceptions;
import 'account_details.dart';
import 'account_list_tile.dart';
import 'login_with_microsoft_dialog.dart';
import 'upsert_offline_account_dialog.dart';
import 'utils/minecraft_account_service_exception_messages.dart';

class AccountsTab extends StatelessWidget {
  const AccountsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select((AccountCubit cubit) => cubit.state.status);

    if (status == AccountStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (status == AccountStatus.loadFailure) {
      final exceptionWithStackTrace = context.select(
        (AccountCubit cubit) => cubit.state.exceptionWithStackTrace,
      );
      return UnknownError(
        onTryAgain: () => context.read<AccountCubit>().loadAccounts(),
        message: context.loc.unknownErrorWhileLoadingAccounts,
        exceptionWithStackTrace: exceptionWithStackTrace!,
      );
    }

    final hasNoAccounts = context.select(
      (AccountCubit cubit) => cubit.state.accounts.list.isEmpty,
    );

    if (hasNoAccounts) {
      return const _EmptyAccounts();
    }

    return SplitView(
      primaryPaneTitle: context.loc.accounts,
      primaryPane: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.85,
        child: Column(
          children: [
            SearchField(
              onSubmitted:
                  (searchQuery) =>
                      context.read<AccountCubit>().searchAccounts(searchQuery),
              onChanged:
                  (searchQuery) =>
                      context.read<AccountCubit>().searchAccounts(searchQuery),
            ),
            const _AccountsList(),

            const _AddAccountButton(useFloatingActionButton: true),
          ],
        ),
      ),
      secondaryPane:
          BlocSelector<AccountCubit, AccountState, MinecraftAccount?>(
            selector: (state) => state.selectedAccount,
            builder: (context, selectedAccount) {
              return selectedAccount != null
                  ? AccountDetails(
                    account: selectedAccount,
                    imagePicker: context.read<ImagePicker>(),
                  )
                  : const SizedBox();
            },
          ),
    );
  }
}

class _AccountsList extends StatelessWidget {
  const _AccountsList();

  @override
  Widget build(BuildContext context) {
    final displayAccounts = context.select(
      (AccountCubit cubit) => cubit.state.displayAccounts,
    );
    final selectedAccountId = context.select(
      (AccountCubit cubit) => cubit.state.selectedAccountId,
    );
    return Expanded(
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        itemBuilder: (context, index) {
          final account = displayAccounts[index];
          return Padding(
            key: ValueKey('${account.id}/$index'),
            padding: const EdgeInsets.only(top: 8),
            child: AccountListTile(
              account: account,
              key: ValueKey(account.id),
              isSelected: selectedAccountId == account.id,
            ),
          );
        },
        itemCount: displayAccounts.length,
      ),
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
              (context, controller, child) => BlocListener<
                MicrosoftAccountHandlerCubit,
                MicrosoftAccountHandlerState
              >(
                listener: (context, state) {
                  if (state.microsoftRefreshAccountStatus ==
                      MicrosoftRefreshAccountStatus.success) {
                    context.scaffoldMessenger.showSnackBarText(
                      context.loc.accountRefreshedMessage(
                        state.requireRecentAccount.username,
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
                      // TODO: TEST THIS CHANGE MANUALLY
                      case minecraft_account_service_exceptions.MinecraftAccountRefresherException():
                        switch (exception.exception) {
                          case minecraft_account_refresher_exceptions.InvalidMicrosoftRefreshTokenException():
                            scaffoldMessenger.showSnackBarText(
                              context.loc.sessionExpiredOrAccessRevoked,
                              snackBarAction: SnackBarAction(
                                label: context.loc.signInWithMicrosoft,
                                onPressed:
                                    () => LoginWithMicrosoftDialog.show(
                                      context,
                                      isRAauthentication: true,
                                    ),
                              ),
                            );
                          case minecraft_account_refresher_exceptions.MicrosoftReAuthRequiredException():
                            scaffoldMessenger.showSnackBarText(
                              message,
                              snackBarAction: SnackBarAction(
                                label: context.loc.signInWithMicrosoft,
                                onPressed:
                                    () => LoginWithMicrosoftDialog.show(
                                      context,
                                      isRAauthentication: true,
                                    ),
                              ),
                            );
                        }
                      case _:
                        scaffoldMessenger.showSnackBarText(message);
                    }

                    context
                        .read<MicrosoftAccountHandlerCubit>()
                        .resetRefreshStatus();
                  }
                },
                child: Builder(
                  builder: (context) {
                    void onPressed() {
                      final state =
                          context.read<MicrosoftAccountHandlerCubit>().state;

                      final isRefreshingAccount =
                          state.microsoftRefreshAccountStatus ==
                          MicrosoftRefreshAccountStatus.loading;
                      final isAlreadyLoggingIn =
                          state.microsoftLoginStatus ==
                          MicrosoftLoginStatus.loading;

                      if (isAlreadyLoggingIn || isRefreshingAccount) {
                        context.scaffoldMessenger.showSnackBarText(
                          context.loc.waitForOngoingTask,
                        );
                        return;
                      }

                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    }

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
