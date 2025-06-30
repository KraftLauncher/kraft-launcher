import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kraft_launcher/account/logic/launcher_minecraft_account/minecraft_account.dart';
import 'package:kraft_launcher/account/ui/account_cubit/account_cubit.dart';
import 'package:kraft_launcher/account/ui/skin/skin_icon_image.dart';
import 'package:kraft_launcher/common/constants/constants.dart';
import 'package:kraft_launcher/common/ui/utils/build_context_ext.dart';
import 'package:kraft_launcher/common/ui/widgets/split_view.dart';

class AccountListTile extends StatelessWidget {
  const AccountListTile({
    super.key,
    required this.account,
    required this.isSelected,
  });

  final MinecraftAccount account;
  final bool isSelected;

  @override
  Widget build(BuildContext context) => PrimaryTilePane(
    title: Text(account.username),
    leading: SkinIconImage(account: account, useCircleAvatar: false),
    trailing: () {
      final microsoftAccountInfo = account.microsoftAccountInfo;
      if (microsoftAccountInfo == null || !account.isMicrosoft) {
        return null;
      }
      final reauthRequiredReason = microsoftAccountInfo.reauthRequiredReason;
      if (reauthRequiredReason == null) {
        return null;
      }
      final (String label, String message) = switch (reauthRequiredReason) {
        MicrosoftReauthRequiredReason.accessRevoked => (
          context.loc.revoked,
          context.loc.reAuthRequiredDueToAccessRevoked,
        ),
        MicrosoftReauthRequiredReason.refreshTokenExpired => (
          context.loc.expired,
          context.loc.reAuthRequiredDueToInactivity(
            MicrosoftConstants.refreshTokenExpiresInDays,
          ),
        ),
        MicrosoftReauthRequiredReason.tokensMissingFromSecureStorage => (
          context.loc.unavailable,
          context.loc.reAuthRequiredDueToMissingSecureAccountDataDetailed,
        ),
        MicrosoftReauthRequiredReason.tokensMissingFromFileStorage => (
          context.loc.unavailable,
          context.loc.reAuthRequiredDueToMissingAccountTokensFromFileStorage,
        ),
      };
      return Tooltip(
        richMessage: WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Container(
            padding: const EdgeInsets.all(10),
            constraints: const BoxConstraints(maxWidth: 250),
            child: Text(
              message,
              style: TextStyle(
                color: context.isDark ? Colors.black : Colors.white,
              ),
            ),
          ),
        ),
        child: Badge(
          label: Text(label),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      );
    }(),
    onTap: () => context.read<AccountCubit>().updateSelectedAccount(account.id),
    selected: isSelected,
  );
}
