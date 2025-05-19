import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../common/constants/constants.dart';
import '../../common/ui/utils/build_context_ext.dart';
import '../../common/ui/widgets/split_view.dart';
import '../data/minecraft_account.dart';
import '../logic/account_cubit.dart';
import 'skin/skin_icon_image.dart';

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
    trailing:
        account.isMicrosoft &&
                (account.microsoftAccountInfo?.needsReAuthentication ?? false)
            ? () {
              final microsoftRefreshTokenExpired =
                  account
                      .microsoftAccountInfo
                      ?.microsoftOAuthRefreshToken
                      .hasExpired ??
                  false;
              return Tooltip(
                richMessage: WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    constraints: const BoxConstraints(maxWidth: 250),
                    child: Text(
                      microsoftRefreshTokenExpired
                          ? context.loc.reAuthenticationRequiredDueToInactivity(
                            MicrosoftConstants.refreshTokenExpiresInDays,
                          )
                          : context
                              .loc
                              .reAuthenticationRequiredDueToAccessRevoked,
                      style: TextStyle(
                        color: context.isDark ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ),
                child: Badge(
                  label: Text(
                    microsoftRefreshTokenExpired
                        ? context.loc.expired
                        : context.loc.revoked,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              );
            }()
            : null,
    onTap: () => context.read<AccountCubit>().updateSelectedAccount(account.id),
    selected: isSelected,
  );
}
