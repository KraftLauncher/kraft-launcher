import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../common/ui/widgets/split_view.dart';
import '../data/minecraft_account.dart';
import '../logic/account_cubit.dart';
import 'skin/skin_icon_image.dart';

class AccountListTile extends StatelessWidget {
  const AccountListTile({
    super.key,
    required this.account,
    required this.index,
    required this.isSelected,
  });

  final MinecraftAccount account;
  final int index;
  final bool isSelected;

  @override
  Widget build(BuildContext context) => PrimaryTilePane(
    title: Text(account.username),
    leading: SkinIconImage(account: account, useCircleAvatar: false),
    onTap: () => context.read<AccountCubit>().updateSelectedAccount(index),
    selected: isSelected,
  );
}
