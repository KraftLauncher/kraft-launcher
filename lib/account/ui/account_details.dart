import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../common/constants/constants.dart';
import '../../common/constants/project_info_constants.dart';
import '../../common/ui/utils/build_context_ext.dart';
import '../../common/ui/utils/scaffold_messenger_ext.dart';
import '../data/launcher_minecraft_account/minecraft_account.dart';
import '../logic/account_cubit/account_cubit.dart';
import '../logic/microsoft/cubit/microsoft_auth_cubit.dart';
import '../logic/microsoft/minecraft/account_service/minecraft_auth_progress.dart';
import 'skin/full_skin_image.dart';
import 'upsert_offline_account_dialog.dart';
import 'utils/auth_progress_messages.dart';

class AccountDetails extends StatelessWidget {
  const AccountDetails({
    super.key,
    required this.account,
    required this.imagePicker,
  });

  final MinecraftAccount account;
  final ImagePicker imagePicker;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(account.username, style: context.theme.textTheme.headlineLarge),
      const SizedBox(height: 40),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FullSkinImage(account: account),
          const SizedBox(width: 36),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ListTile(
                  title: Text(context.loc.username),
                  subtitle: Text(account.username),
                  leading: const Icon(Icons.person),
                  trailing: Icon(
                    account.isMicrosoft ? Icons.open_in_new : null,
                  ),
                  onTap: () {
                    switch (account.accountType) {
                      case AccountType.microsoft:
                        launchUrl(
                          Uri.parse(
                            MinecraftConstants.changeMinecraftUsernameLink,
                          ),
                        );
                      case AccountType.offline:
                        showDialog<void>(
                          context: context,
                          builder:
                              (context) => UpsertOfflineAccountDialog(
                                offlineAccountToUpdate: account,
                              ),
                        );
                    }
                  },
                  shape: _shape,
                ),
                ListTile(
                  title: Text(context.loc.accountType),
                  subtitle: Text(switch (account.accountType) {
                    AccountType.microsoft => context.loc.microsoft,
                    AccountType.offline => context.loc.offline,
                  }),
                  leading: const Icon(Icons.account_circle),
                  shape: _shape,
                ),
                ListTile(
                  title: Text(context.loc.minecraftId),
                  subtitle: Text(account.id),
                  leading: const Icon(Icons.badge),
                  onTap: () async {
                    final scaffoldMessenger = context.scaffoldMessenger;
                    final loc = context.loc;
                    await Clipboard.setData(ClipboardData(text: account.id));
                    await scaffoldMessenger.showSnackBarText(
                      loc.copiedToClipboard,
                    );
                  },
                  shape: _shape,
                ),
                if (account.isMicrosoft)
                  BlocSelector<
                    MicrosoftAuthCubit,
                    MicrosoftAuthState,
                    MicrosoftRefreshAccountStatus
                  >(
                    selector: (state) => state.refreshStatus,
                    builder: (context, refreshStatus) {
                      if (refreshStatus ==
                          MicrosoftRefreshAccountStatus.loading) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            spacing: 8,
                            children: [
                              BlocSelector<
                                MicrosoftAuthCubit,
                                MicrosoftAuthState,
                                MinecraftAuthProgress?
                              >(
                                selector:
                                    (state) => state.refreshAccountProgress,
                                builder:
                                    (context, authProgress) => Text(
                                      authProgress.getMessage(context.loc),
                                    ),
                              ),
                              const LinearProgressIndicator(),
                            ],
                          ),
                        );
                      }
                      return ListTile(
                        title: Text(context.loc.refreshAccount),
                        leading: const Icon(Icons.refresh),
                        onTap: () {
                          final cubit = context.read<MicrosoftAuthCubit>();
                          final state = cubit.state;
                          final isLoggingIn =
                              state.loginStatus == MicrosoftLoginStatus.loading;

                          if (isLoggingIn) {
                            context.scaffoldMessenger.showSnackBarText(
                              context.loc.waitForOngoingTask,
                            );
                            return;
                          }

                          cubit.refreshMicrosoftAccount(account);
                        },
                      );
                    },
                  ),
                if (account.isMicrosoft)
                  ListTile(
                    title: Text(context.loc.updateSkin),
                    leading: const Icon(Icons.brush),
                    trailing: const Icon(Icons.chevron_right),
                    onTap:
                        () => context.scaffoldMessenger.showSnackBarText(
                          context.loc.featureUnsupportedYet,
                        ),
                  ),
                if (account.isMicrosoft)
                  ListTile(
                    title: Text(context.loc.revokeAccess),
                    leading: const Icon(Icons.no_accounts),
                    trailing: const Icon(Icons.open_in_new),
                    onTap:
                        () => launchUrl(
                          Uri.parse(
                            ProjectInfoConstants.microsoftRevokeAccessLink,
                          ),
                        ),
                  ),
                ListTile(
                  onTap: () async {
                    final accountCubit = context.read<AccountCubit>();
                    final confirmed =
                        await showDialog<bool>(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: Text(
                                  context.loc.removeAccountConfirmation,
                                ),
                                content: Text(
                                  context.loc.removeAccountConfirmationNotice,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.pop(context, false),

                                    child: Text(context.loc.cancel),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.pop(context, true),
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          context.theme.colorScheme.error,
                                    ),
                                    child: Text(context.loc.remove),
                                  ),
                                ],
                              ),
                        ) ??
                        false;
                    if (!confirmed) {
                      return;
                    }
                    await accountCubit.removeAccount(account.id);
                  },
                  title: Text(
                    context.loc.removeAccount,
                    style: context.theme.textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w400,
                      color: context.theme.colorScheme.error,
                    ),
                  ),
                  hoverColor: context.theme.colorScheme.error.withAlpha(20),
                  focusColor: context.theme.colorScheme.error.withAlpha(30),
                  splashColor: context.theme.colorScheme.error.withAlpha(30),
                  leading: Icon(
                    Icons.delete,
                    color: context.theme.colorScheme.error,
                  ),
                  shape: _shape,
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  );

  ShapeBorder get _shape =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(15));
}
