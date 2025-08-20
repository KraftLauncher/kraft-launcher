import 'dart:io';

import 'package:integration_test/integration_test.dart';
import 'package:kraft_launcher/account/data/microsoft_auth_api/microsoft_auth_api.dart';
import 'package:kraft_launcher/account/data/redirect_http_server_handler/dart_redirect_http_server_handler.dart';
import 'package:kraft_launcher/account/data/redirect_http_server_handler/redirect_http_server_handler.dart';
import 'package:kraft_launcher/account/logic/microsoft/auth_flows/auth_code/microsoft_auth_code_flow.dart';
import 'package:kraft_launcher/common/constants/constants.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../test/common/helpers/dio_utils.dart';
import '../test/common/helpers/mocks.dart';
import '../test/common/test_constants.dart';

// This minimal integration test verifies the real HTTP server behavior of
// MicrosoftAuthCodeFlow. While most logic is covered by unit tests using
// a mocked HttpServer for performance and isolation, this test ensures that the real server
// starts, stops, and handles auth code redirects correctly.

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockMicrosoftAuthApi mockMicrosoftAuthApi;
  late MicrosoftAuthCodeFlow microsoftAuthCodeFlow;

  late RedirectHttpServerHandler redirectHttpServerHandler;

  setUp(() {
    mockMicrosoftAuthApi = MockMicrosoftAuthApi();

    redirectHttpServerHandler = DartRedirectHttpServerHandler();
    microsoftAuthCodeFlow = MicrosoftAuthCodeFlow(
      microsoftAuthApi: mockMicrosoftAuthApi,
      // Runs a real HTTP server
      redirectHttpServerHandler: redirectHttpServerHandler,
    );
  });

  const address = '127.0.0.1';
  const port = MicrosoftAuthCodeFlow.serverPort;

  Future<void> startServer() async {
    await redirectHttpServerHandler.start(port: port);
    if (!redirectHttpServerHandler.isRunning) {
      throw StateError(
        'Server should be running after start. This is likely a bug either in production or test code.',
      );
    }
  }

  Future<void> closeServer() async {
    await microsoftAuthCodeFlow.closeServer();
    if (redirectHttpServerHandler.isRunning) {
      throw StateError(
        'Server should not be running after close. This is likely a bug either in production or test code.',
      );
    }
  }

  tearDown(() async {
    await microsoftAuthCodeFlow.closeServer();
  });

  test('server is reachable when started', () async {
    await startServer();

    expect(await _isPortOpen(address, port), true);
  });

  test('server is not reachable when stopped', () async {
    await startServer();

    await closeServer();

    expect(await _isPortOpen(address, port), false);
  });

  Uri serverUri({
    required String? authCodeParam,
    String? errorCodeParam,
    String? errorDescriptionParam,
  }) {
    return Uri.http('$address:$port', '/', {
      if (authCodeParam != null)
        MicrosoftConstants.loginRedirectAuthCodeQueryParamName: authCodeParam,
      if (errorCodeParam != null)
        MicrosoftConstants.loginRedirectErrorQueryParamName: errorCodeParam,
      if (errorDescriptionParam != null)
        MicrosoftConstants.loginRedirectErrorDescriptionQueryParamName:
            errorDescriptionParam,
    });
  }

  test('completes full auth code flow correctly', () async {
    when(
      () => mockMicrosoftAuthApi.userLoginUrlWithAuthCode(),
    ).thenAnswer((_) => TestConstants.anyString);

    const expectedTokenResponse = MicrosoftOAuthTokenResponse(
      accessToken: TestConstants.anyString,
      refreshToken: TestConstants.anyString,
      expiresIn: TestConstants.anyInt,
    );
    when(
      () => mockMicrosoftAuthApi.exchangeAuthCodeForTokens(any()),
    ).thenAnswer((_) async => expectedTokenResponse);
    const microsoftAuthCodeResponsePageContent =
        MicrosoftAuthCodeResponsePageContent(
          pageTitle: 'Example page title',
          pageDir: 'ltr',
          pageLangCode: 'en',
          title: 'Example title',
          subtitle: 'Example subtitle',
        );
    final future = microsoftAuthCodeFlow.run(
      onProgress: (_) {},
      onAuthCodeLoginUrlAvailable: (_) {},
      authCodeResponsePageVariants: MicrosoftAuthCodeResponsePageVariants(
        approved: microsoftAuthCodeResponsePageContent,
        accessDenied: microsoftAuthCodeResponsePageContent,
        missingAuthCode: microsoftAuthCodeResponsePageContent,
        unknownError: (_, _) => microsoftAuthCodeResponsePageContent,
      ),
    );

    const fakeAuthCode = 'example-auth-code';
    final redirectPageHtml = (await DioTestClient.instance.getUri<String?>(
      serverUri(authCodeParam: fakeAuthCode),
    )).data;

    expect(
      redirectPageHtml,
      buildAuthCodeResultHtmlPage(
        microsoftAuthCodeResponsePageContent,
        isSuccess: true,
      ),
    );

    final actualTokenResponse = await future.timeout(
      const Duration(seconds: 1),
    );
    expect(actualTokenResponse, same(expectedTokenResponse));
  });
}

Future<bool> _isPortOpen(
  String host,
  int port, {
  Duration timeout = const Duration(seconds: 1),
}) async {
  try {
    final socket = await Socket.connect(host, port, timeout: timeout);
    socket.destroy();
    return true;
  } on Exception catch (_) {
    return false;
  }
}
