import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kraft_launcher/account/logic/launcher_minecraft_account/minecraft_account.dart';
import 'package:kraft_launcher/account/ui/account_cubit/account_cubit.dart';
import 'package:kraft_launcher/common/ui/utils/build_context_ext.dart';

class UpsertOfflineAccountDialog extends StatefulWidget {
  const UpsertOfflineAccountDialog({
    super.key,
    required this.offlineAccountToUpdate,
  });

  final MinecraftAccount? offlineAccountToUpdate;

  @override
  State<UpsertOfflineAccountDialog> createState() =>
      _UpsertOfflineAccountDialogState();
}

class _UpsertOfflineAccountDialogState
    extends State<UpsertOfflineAccountDialog> {
  late TextEditingController _usernameController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(
      text: widget.offlineAccountToUpdate?.username,
    );
  }

  static const _minLength = 3;
  static const _maxLength = 16;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.offlineAccountToUpdate != null
          ? context.loc.updateOfflineAccount
          : context.loc.createOfflineAccount,
    ),
    content: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500, minHeight: 100),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.loc.offlineMinecraftAccountCreationNotice),
            const SizedBox(height: 12),
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: context.loc.username,
                hintText: context.loc.minecraftUsernameHint,
                border: const OutlineInputBorder(),
                counterText: () {
                  final length = _usernameController.text.length;
                  if (length < _minLength) {
                    return '${_minLength - length}';
                  }
                  if (length > _maxLength) {
                    return '${_maxLength - length}';
                  }
                  return '${_maxLength - length}';
                }(),
              ),
              onFieldSubmitted: (value) => _create(),
              onChanged: (value) => setState(() {}),
              validator: (username) {
                if (username!.trim().isEmpty) {
                  return context.loc.usernameEmptyError;
                }
                if (username.length < _minLength) {
                  return context.loc.usernameTooShortError;
                }

                if (username.length > _maxLength) {
                  return context.loc.usernameTooLongError;
                }

                if (username.trim().contains(' ')) {
                  return context.loc.usernameContainsWhitespacesError;
                }

                final validUsernameCharactersRegex = RegExp(r'^[a-zA-Z0-9_]+$');
                if (!validUsernameCharactersRegex.hasMatch(username)) {
                  return context.loc.usernameInvalidCharactersError;
                }
                return null;
              },
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => context.pop(),
        child: Text(context.loc.cancel),
      ),
      TextButton(
        onPressed: (_formKey.currentState?.validate() ?? false)
            ? _create
            : null,
        child: Text(
          widget.offlineAccountToUpdate != null
              ? context.loc.update
              : context.loc.create,
        ),
      ),
    ],
  );

  void _create() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final offlineAccountToUpdate = widget.offlineAccountToUpdate;
    if (offlineAccountToUpdate != null) {
      context.read<AccountCubit>().updateOfflineAccount(
        accountId: offlineAccountToUpdate.id,
        username: _usernameController.text,
      );
    } else {
      context.read<AccountCubit>().createOfflineAccount(
        username: _usernameController.text,
      );
    }
    context.pop();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }
}
