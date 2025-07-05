/// @docImport 'package:kraft_launcher/account/logic/microsoft/auth_flows/device_code/microsoft_device_code_flow.dart';
/// @docImport 'package:kraft_launcher/account/logic/microsoft/auth_flows/microsoft_oauth_flow_controller.dart';
library;

import 'dart:async';
import 'dart:io';

import 'package:kraft_launcher/account/data/microsoft_auth_api/microsoft_auth_api.dart';
import 'package:kraft_launcher/account/logic/microsoft/auth_flows/auth_code/microsoft_auth_code_flow_exceptions.dart'
    as microsoft_auth_code_flow_exceptions;
import 'package:kraft_launcher/common/constants/constants.dart';
import 'package:kraft_launcher/common/constants/project_info_constants.dart';
import 'package:kraft_launcher/common/logic/app_logger.dart';
import 'package:meta/meta.dart';

@visibleForTesting
typedef HttpServerFactory =
    Future<HttpServer> Function(InternetAddress address, int port);

/// Handles Microsoft OAuth authorization code flow (not specific to Minecraft).
///
/// Provides the URL for the user to open on Microsoft’s site—usually
/// opened in the user’s system browser.
///
/// Runs a temporary HTTP server to receive the redirect after login,
/// which may contain an authorization code on success,
/// or error code and description in case of failure.
///
/// Responds with an HTML page indicating success, rejection,
/// missing authorization code, or unknown errors.
///
/// On successful authentication, exchanges the authorization code
/// for Microsoft OAuth access and refresh tokens.
///
/// See also:
///
/// * [MicrosoftDeviceCodeFlow], for Microsoft device code authentication.
/// * [MicrosoftOAuthFlowController], that manages both [MicrosoftAuthCodeFlow] and [MicrosoftDeviceCodeFlow].
class MicrosoftAuthCodeFlow {
  MicrosoftAuthCodeFlow({
    required this.microsoftAuthApi,
    @visibleForTesting HttpServerFactory? httpServerFactory,
  }) : _httpServerFactory = httpServerFactory ?? HttpServer.bind;

  @visibleForTesting
  final MicrosoftAuthApi microsoftAuthApi;

  final HttpServerFactory _httpServerFactory;

  /// Minimal HTTP server for handling Microsoft's redirect in the auth code flow.
  /// Microsoft will redirect to this server with the auth code after the user logs in.
  @visibleForTesting
  HttpServer? httpServer;

  @visibleForTesting
  HttpServer get serverOrThrow =>
      httpServer ??
      (throw StateError(
        'The auth code redirect HTTP server has not started yet which is required to handle auth code flow login result.',
      ));

  bool get isServerRunning => httpServer != null;

  Future<HttpServer> startServer() async {
    assert(
      !isServerRunning,
      'The Microsoft Auth Redirect server cannot be started if it is already running.',
    );
    httpServer = await _httpServerFactory(
      InternetAddress.loopbackIPv4,
      ProjectInfoConstants.microsoftLoginRedirectPort,
    );
    AppLogger.i('Starting Microsoft Auth Code server');
    return serverOrThrow;
  }

  Future<void> stopServer() async {
    assert(
      isServerRunning,
      "The Microsoft Auth Redirect server cannot be stopped if it hasn't started yet.",
    );
    await serverOrThrow.close();
    httpServer = null;
    AppLogger.i('Stopping Microsoft Auth Code server');
  }

  Future<bool> stopServerIfRunning() async {
    if (isServerRunning) {
      await stopServer();
      return true;
    }
    return false;
  }

  Future<MicrosoftOAuthTokenResponse?> run({
    required AuthCodeProgressCallback onProgress,
    required AuthCodeLoginUrlAvailableCallback onAuthCodeLoginUrlAvailable,
    // The page content is not hardcoded for localization.
    required MicrosoftAuthCodeResponsePageVariants authCodeResponsePageVariants,
  }) async {
    final server = serverOrThrow;

    final authCodeLoginUrl = microsoftAuthApi.userLoginUrlWithAuthCode();

    onProgress(MicrosoftAuthCodeProgress.waitingForUserLogin);
    onAuthCodeLoginUrlAvailable(authCodeLoginUrl);

    // Wait for the user response
    final request = await server.firstOrNull;
    if (request == null) {
      // The server was closed because the user didn't log in.
      // It automatically shuts down when the login dialog is closed.
      return null;
    }

    Future<void> respondAndStopServer(String html) async {
      final response = request.response;
      response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..write(html);
      await response.close();
      await stopServer();
    }

    final code =
        request.uri.queryParameters[MicrosoftConstants
            .loginRedirectAuthCodeQueryParamName];

    final error =
        request.uri.queryParameters[MicrosoftConstants
            .loginRedirectErrorQueryParamName];
    final errorDescription =
        request.uri.queryParameters[MicrosoftConstants
            .loginRedirectErrorDescriptionQueryParamName];

    if (error != null) {
      if (error == MicrosoftConstants.loginRedirectAccessDeniedErrorCode) {
        await respondAndStopServer(
          buildAuthCodeResultHtmlPage(
            authCodeResponsePageVariants.accessDenied,
            isSuccess: false,
          ),
        );
        throw const microsoft_auth_code_flow_exceptions.AuthCodeDeniedException();
      }

      await respondAndStopServer(
        buildAuthCodeResultHtmlPage(
          authCodeResponsePageVariants.unknownError(
            error,
            errorDescription.toString(),
          ),
          isSuccess: false,
        ),
      );
      throw microsoft_auth_code_flow_exceptions.AuthCodeRedirectException(
        error: error,
        errorDescription: errorDescription.toString(),
      );
    }
    if (code == null) {
      await respondAndStopServer(
        buildAuthCodeResultHtmlPage(
          authCodeResponsePageVariants.missingAuthCode,
          isSuccess: false,
        ),
      );
      throw const microsoft_auth_code_flow_exceptions.AuthCodeMissingException();
    }
    await respondAndStopServer(
      buildAuthCodeResultHtmlPage(
        authCodeResponsePageVariants.approved,
        isSuccess: true,
      ),
    );

    onProgress(MicrosoftAuthCodeProgress.exchangingAuthCode);

    final oauthTokenResponse = await microsoftAuthApi.exchangeAuthCodeForTokens(
      code,
    );

    return oauthTokenResponse;
  }
}

@immutable
class MicrosoftAuthCodeResponsePageContent {
  const MicrosoftAuthCodeResponsePageContent({
    required this.pageTitle,
    required this.title,
    required this.subtitle,
    required this.pageLangCode,
    required this.pageDir,
  });
  final String pageTitle;
  final String title;
  final String subtitle;
  final String pageLangCode;
  final String pageDir;
}

@immutable
class MicrosoftAuthCodeResponsePageVariants {
  const MicrosoftAuthCodeResponsePageVariants({
    required this.approved,
    required this.accessDenied,
    required this.missingAuthCode,
    required this.unknownError,
  });

  final MicrosoftAuthCodeResponsePageContent approved;
  final MicrosoftAuthCodeResponsePageContent accessDenied;
  final MicrosoftAuthCodeResponsePageContent missingAuthCode;
  final MicrosoftAuthCodeResponsePageContent Function(
    String errorCode,
    String errorDescription,
  )
  unknownError;
}

// Since the authorization code flow requires a redirect URI,
// the app temporarily starts a local server to handle the redirect request,
// which contains the authorization code needed to complete login.
@visibleForTesting
String buildAuthCodeResultHtmlPage(
  MicrosoftAuthCodeResponsePageContent content, {
  required bool isSuccess,
}) => '''
<!DOCTYPE html>
<html lang="${content.pageLangCode}" dir="${content.pageDir}">
<head>
  <meta charset="UTF-8" />
  <title>${content.pageTitle}</title>
  <style>
    html, body {
      margin: 0;
      padding: 0;
      height: 100%;
      background: #f3f4f6;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .box {
      text-align: center;
      background: white;
      padding: 2rem 3rem;
      border-radius: 1rem;
      box-shadow: 0 10px 30px rgba(0,0,0,0.1);
    }
    .box h1 {
      margin: 0;
      font-size: 1.5rem;
      color: #2563eb;
    }
    .box p {
      margin-top: 0.5rem;
      color: #4b5563;
    }
  </style>
</head>
<body>
  <div class="box">
    <h1>${isSuccess ? '✅' : '❌'} ${content.title}</h1>
    <p>${content.subtitle}</p>
  </div>
</body>
</html>
''';

extension _HttpServerExt on HttpServer {
  Future<HttpRequest?> get firstOrNull {
    final completer = Completer<HttpRequest?>();
    late StreamSubscription<HttpRequest> serverSubscription;

    serverSubscription = listen(
      (request) {
        if (!completer.isCompleted) {
          completer.complete(request);
          serverSubscription.cancel();
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
      onError: (Object error, StackTrace stack) {
        if (!completer.isCompleted) {
          completer.completeError(error, stack);
        }
      },
      cancelOnError: true,
    );

    return completer.future;
  }
}

enum MicrosoftAuthCodeProgress { waitingForUserLogin, exchangingAuthCode }

typedef AuthCodeProgressCallback =
    void Function(MicrosoftAuthCodeProgress progress);

typedef AuthCodeLoginUrlAvailableCallback =
    void Function(String authCodeLoginUrl);
