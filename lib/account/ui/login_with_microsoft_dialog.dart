import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../common/constants/constants.dart';
import '../../common/constants/project_info_constants.dart';
import '../../common/ui/utils/build_context_ext.dart';
import '../../common/ui/utils/scaffold_messenger_ext.dart';
import '../../common/ui/widgets/copy_code_block.dart';
import '../../settings/logic/cubit/settings_cubit.dart';
import '../data/microsoft_auth_api/microsoft_auth_api_exceptions.dart'
    as microsoft_auth_api_exceptions;
import '../logic/microsoft/auth_flows/auth_code/microsoft_auth_code_flow.dart';
import '../logic/microsoft/cubit/microsoft_account_handler_cubit.dart';
import '../logic/microsoft/minecraft/account_resolver/minecraft_account_resolver_exceptions.dart';
import '../logic/microsoft/minecraft/account_service/minecraft_account_service_exceptions.dart'
    as minecraft_account_service_exceptions;
import 'minecraft_java_entitlement_absent_dialog.dart';
import 'utils/auth_progress_messages.dart';
import 'utils/minecraft_account_service_exception_messages.dart';

class LoginWithMicrosoftDialog extends StatefulWidget {
  const LoginWithMicrosoftDialog({super.key});

  @override
  State<LoginWithMicrosoftDialog> createState() =>
      _LoginWithMicrosoftDialogState();

  static void show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => const LoginWithMicrosoftDialog(),
  );
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
                final username = state.requireRecentAccount.username;
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

                // Handle special errors
                switch (exception) {
                  case minecraft_account_service_exceptions.MicrosoftAuthApiException():
                    final microsoftAuthApiException = exception.exception;
                    switch (microsoftAuthApiException) {
                      case microsoft_auth_api_exceptions.XstsErrorException():
                        switch (microsoftAuthApiException.xstsError) {
                          case microsoft_auth_api_exceptions
                              .XstsError
                              .accountCreationRequired:
                            scaffoldMessenger.showSnackBarText(
                              message,
                              snackBarAction: SnackBarAction(
                                label: context.loc.createXboxAccount,
                                onPressed:
                                    () => launchUrl(
                                      Uri.parse(
                                        MicrosoftConstants
                                            .createXboxAccountLink,
                                      ),
                                    ),
                              ),
                            );

                          case _:
                            scaffoldMessenger.showSnackBarText(message);
                        }
                      case _:
                        scaffoldMessenger.showSnackBarText(message);
                    }

                  case minecraft_account_service_exceptions.MinecraftAccountResolverException():
                    switch (exception.exception) {
                      case MinecraftJavaEntitlementAbsentException():
                        showDialog<void>(
                          context: context,
                          builder:
                              (context) =>
                                  const MinecraftJavaEntitlementAbsentDialog(),
                        );
                    }

                  case _:
                    scaffoldMessenger.showSnackBarText(message);
                }
              }
            },
            builder: (context, state) {
              if (state.microsoftLoginStatus == MicrosoftLoginStatus.loading ||
                  // While the listener is processing and about to close the dialog,
                  // keep showing the loading state even after a success to avoid a UI flash.
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

                      // TODO: BUG: CONFLICTING WITH DEVICE CODE when request was not sent yet and "Sign in via browser was pressed"
                      if (state.authProgress?.authCodeProgress?.progress ==
                          MicrosoftAuthCodeProgress.waitingForUserLogin)
                        () {
                          final authCodeLoginUrl =
                              state.requireAuthCodeLoginUrl;
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
                    onPressed: () {
                      final pageDir = Directionality.of(context).name;
                      final pageLangCode =
                          context
                              .read<SettingsCubit>()
                              .state
                              .settings
                              .general
                              .appLanguage
                              .localeCode;
                      _microsoftAccountHandlerCubit.loginWithMicrosoftAuthCode(
                        authCodeResponsePageVariants:
                            MicrosoftAuthCodeResponsePageVariants(
                              approved: MicrosoftAuthCodeResponsePageContent(
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
                                pageDir: pageDir,
                                pageLangCode: pageLangCode,
                              ),
                              accessDenied:
                                  MicrosoftAuthCodeResponsePageContent(
                                    pageTitle: context.loc.errorOccurred,
                                    title: context.loc.errorOccurred,
                                    subtitle: context.loc.loginAttemptRejected,
                                    pageLangCode: pageLangCode,
                                    pageDir: pageDir,
                                  ),
                              missingAuthCode:
                                  MicrosoftAuthCodeResponsePageContent(
                                    pageTitle: context.loc.errorOccurred,
                                    title: context.loc.errorOccurred,
                                    subtitle: context.loc.missingAuthCodeError,
                                    pageLangCode: pageLangCode,
                                    pageDir: pageDir,
                                  ),
                              unknownError:
                                  (errorCode, errorDescription) =>
                                      MicrosoftAuthCodeResponsePageContent(
                                        pageTitle: context.loc.errorOccurred,
                                        title: context.loc.errorOccurred,
                                        subtitle: context.loc
                                            .authCodeLoginUnknownError(
                                              errorCode,
                                              errorDescription,
                                            ),
                                        pageLangCode: pageLangCode,
                                        pageDir: pageDir,
                                      ),
                            ),
                      );
                    },
                    label: Text(context.loc.signInViaBrowser),
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
                          code: state.requireRequestedDeviceCode,
                        ),
                        DeviceCodeStatus.expired => Column(
                          spacing: 8,
                          children: [
                            Text(
                              context.loc.loginDeviceCodeExpired,
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
                        DeviceCodeStatus.declined => Column(
                          spacing: 8,
                          children: [
                            Text(
                              context.loc.loginAttemptRejected,
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
