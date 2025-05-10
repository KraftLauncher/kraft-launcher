import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../common/constants/constants.dart';
import '../../common/constants/project_info_constants.dart';
import '../../common/logic/utils.dart';
import '../../common/ui/utils/build_context_ext.dart';
import '../../common/ui/utils/scaffold_messenger_ext.dart';
import '../../common/ui/widgets/copy_code_block.dart';
import '../../settings/logic/cubit/settings_cubit.dart';
import '../data/microsoft_auth_api/microsoft_auth_exceptions.dart';
import '../logic/account_manager/minecraft_account_manager.dart';
import '../logic/account_manager/minecraft_account_manager_exceptions.dart';
import '../logic/microsoft/cubit/microsoft_account_handler_cubit.dart';
import 'utils/account_manager_exception_messages.dart';
import 'utils/auth_progress_messages.dart';

class LoginWithMicrosoftDialog extends StatefulWidget {
  const LoginWithMicrosoftDialog({super.key});

  @override
  State<LoginWithMicrosoftDialog> createState() =>
      _LoginWithMicrosoftDialogState();
}

class _LoginWithMicrosoftDialogState extends State<LoginWithMicrosoftDialog> {
  final _microsoftDeviceLinkTapRecognizer = TapGestureRecognizer();
  late final MicrosoftAccountHandlerCubit _microsoftAccountHandlerCubit;
  bool _canUserClose = true;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _canUserClose,
    child: AlertDialog(
      title: Text(context.loc.addMicrosoftAccount),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 300, minHeight: 100),
        child: SingleChildScrollView(
          child: BlocConsumer<
            MicrosoftAccountHandlerCubit,
            MicrosoftAccountHandlerState
          >(
            listener: (context, state) {
              if (state.microsoftLoginStatus == MicrosoftLoginStatus.loading) {
                setState(() => _canUserClose = false);
                return;
              }

              setState(() => _canUserClose = true);

              if (state.microsoftLoginStatus.isSuccess) {
                final username = state.recentAccountOrThrow.username;
                context.scaffoldMessenger.showSnackBarText(
                  state.microsoftLoginStatus ==
                          MicrosoftLoginStatus.successAccountAdded
                      ? context.loc.loginSuccessAccountAddedMessage(username)
                      : context.loc.loginSuccessAccountUpdatedMessage(username),
                );
                context.pop();
                return;
              }

              if (state.microsoftLoginStatus == MicrosoftLoginStatus.failure) {
                final exception = state.exceptionOrThrow;
                final message = exception.getMessage(context.loc);
                final scaffoldMessenger = context.scaffoldMessenger;

                context.pop();

                // Show SnackBar action for special errors.
                if (exception is MicrosoftApiAccountManagerException) {
                  final microsoftAuthException = exception.authApiException;
                  if (microsoftAuthException
                      is XstsErrorMicrosoftAuthException) {
                    switch (microsoftAuthException.xstsError) {
                      case XstsError.accountCreationRequired:
                        scaffoldMessenger.showSnackBarText(
                          message,
                          snackBarAction: SnackBarAction(
                            label: context.loc.createXboxAccount,
                            onPressed:
                                () => launchUrl(
                                  Uri.parse(
                                    MicrosoftConstants.createXboxAccountLink,
                                  ),
                                ),
                          ),
                        );
                        return;
                      case _:
                    }
                  }
                }

                scaffoldMessenger.showSnackBarText(message);
              }
            },
            builder: (context, state) {
              // While the listener is processing and about to close the dialog,
              // keep showing the loading state even after a success to avoid a UI flash.
              if (state.microsoftLoginStatus == MicrosoftLoginStatus.loading ||
                  state.microsoftLoginStatus.isSuccess) {
                assert(
                  state.authProgress != null,
                  'Expected the auth progress to be not null when login loading',
                );

                final message = state.authProgress.getMessage(context.loc);
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(),
                      ),
                      const SizedBox(height: 16),
                      if (state.authProgress ==
                          MicrosoftAuthProgress.waitingForUserLogin)
                        () {
                          final authCodeLoginUrl =
                              state.authCodeLoginUrl ??
                              (throw Exception(
                                'Expected the auth code login URL to be not null for stats: ${MicrosoftAuthProgress.waitingForUserLogin}',
                              ));
                          return GestureDetector(
                            onTap: () => launchUrl(Uri.parse(authCodeLoginUrl)),
                            onLongPress:
                                () => Clipboard.setData(
                                  ClipboardData(text: authCodeLoginUrl),
                                ),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Text(
                                message,
                                style: context.theme.textTheme.bodyLarge
                                    ?.copyWith(color: Colors.blue),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }()
                      else
                        Text(
                          message,
                          style: context.theme.textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 6),
                  FilledButton.icon(
                    onPressed:
                        () => _microsoftAccountHandlerCubit.loginWithMicrosoftAuthCode(
                          successLoginPageContent:
                              AuthCodeSuccessLoginPageContent(
                                pageTitle:
                                    context
                                        .loc
                                        .authCodeRedirectPageLoginSuccessTitle,
                                title:
                                    context
                                        .loc
                                        .authCodeRedirectPageLoginSuccessTitle,
                                subtitle: context.loc
                                    .authCodeRedirectPageLoginSuccessMessage(
                                      ProjectInfoConstants.displayName,
                                    ),
                                pageDir: Directionality.of(context).name,
                                pageLangCode:
                                    context
                                        .read<SettingsCubit>()
                                        .state
                                        .settings
                                        .general
                                        .appLanguage
                                        .localeCode,
                              ),
                        ),
                    label: Text(context.loc.signInWithMicrosoft),
                    icon: const Icon(Icons.open_in_browser),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          context.loc.or,
                          style: context.theme.textTheme.bodyMedium,
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(context.loc.useDeviceCodeMethod),

                  const SizedBox(height: 12),

                  SelectableText.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '${context.loc.deviceCodeStepVisit} '),
                        TextSpan(
                          text: MicrosoftConstants.microsoftDeviceCodeLink,
                          recognizer:
                              _microsoftDeviceLinkTapRecognizer
                                ..onTap =
                                    () => launchUrl(
                                      Uri.parse(
                                        MicrosoftConstants
                                            .microsoftDeviceCodeLink,
                                      ),
                                    ),
                          style: TextStyle(
                            color: context.theme.colorScheme.primary,
                          ),
                        ),

                        TextSpan(text: '\n${context.loc.deviceCodeStepEnter}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  Builder(
                    builder: (context) {
                      return switch (state.deviceCodeStatus) {
                        DeviceCodeStatus.idle => const SizedBox.shrink(),
                        DeviceCodeStatus.requestingCode => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: LinearProgressIndicator(),
                        ),
                        DeviceCodeStatus.polling => CopyCodeBlock(
                          code: requireNotNull(
                            state.requestedDeviceCode,
                            name: 'requestedDeviceCode',
                          ),
                        ),
                        DeviceCodeStatus.expired => Column(
                          spacing: 8,
                          children: [
                            Text(
                              context.loc.loginCodeExpired,
                              style: context.theme.textTheme.titleMedium,
                            ),
                            ElevatedButton.icon(
                              onPressed:
                                  () =>
                                      _microsoftAccountHandlerCubit
                                          .requestLoginWithMicrosoftDeviceCode(),
                              label: Text(context.loc.tryAgain),
                              icon: const Icon(Icons.refresh),
                            ),
                          ],
                        ),
                      };
                    },
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 140,
                          width: 140,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: QrImageView(
                              backgroundColor: Colors.white,
                              data: MicrosoftConstants.microsoftDeviceCodeLink,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.loc.deviceCodeQrInstruction,
                          style: context.theme.textTheme.bodySmall?.copyWith(
                            color: context.theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.loc.cancel),
        ),
      ],
    ),
  );

  @override
  void initState() {
    super.initState();
    _microsoftAccountHandlerCubit =
        context.read<MicrosoftAccountHandlerCubit>();
    _microsoftAccountHandlerCubit.requestLoginWithMicrosoftDeviceCode();
  }

  @override
  void dispose() {
    _microsoftAccountHandlerCubit.stopServerIfRunning(); // Auth code method
    _microsoftAccountHandlerCubit
        .cancelDeviceCodePollingTimer(); // Device code method
    _microsoftDeviceLinkTapRecognizer.dispose();
    _microsoftAccountHandlerCubit.resetLoginStatus();
    super.dispose();
  }
}
