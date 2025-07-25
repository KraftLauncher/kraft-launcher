import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kraft_launcher/account/ui/account_cubit/account_cubit.dart';
import 'package:kraft_launcher/account/ui/skin/skin_icon_image.dart';
import 'package:kraft_launcher/common/ui/utils/build_context_ext.dart';

class AccountSwitcherIconButton extends StatelessWidget {
  const AccountSwitcherIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    final accounts = context.select(
      (AccountCubit cubit) => cubit.state.accounts,
    );
    return MenuAnchor(
      menuChildren:
          accounts.list.indexed.map((entry) {
            final account = entry.$2;

            return MenuItemButton(
              leadingIcon: SkinIconImage(
                account: account,
                useCircleAvatar: true,
              ),
              child: Text(account.username),
              onPressed:
                  () => context.read<AccountCubit>().updateDefaultAccount(
                    account.id,
                  ),
            );
          }).toList(),
      builder:
          (context, controller, child) => IconButton(
            onPressed:
                () =>
                    controller.isOpen ? controller.close() : controller.open(),
            icon: SkinIconImage(
              account: accounts.defaultAccount,
              useCircleAvatar: true,
            ),
            tooltip: context.loc.switchAccount,
          ),
    );
  }
}
