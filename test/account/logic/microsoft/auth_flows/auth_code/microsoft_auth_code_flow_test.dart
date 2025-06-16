import 'dart:async';
import 'dart:io';

import 'package:kraft_launcher/account/data/microsoft_auth_api/microsoft_auth_api.dart';
import 'package:kraft_launcher/account/logic/microsoft/auth_flows/auth_code/microsoft_auth_code_flow.dart';
import 'package:kraft_launcher/account/logic/microsoft/auth_flows/auth_code/microsoft_auth_code_flow_exceptions.dart'
    as microsoft_auth_code_flow_exceptions;
import 'package:kraft_launcher/common/constants/constants.dart';
import 'package:kraft_launcher/common/constants/project_info_constants.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../../common/helpers/mocks.dart';
import '../../../../../common/test_constants.dart';
import '../../../../data/microsoft_auth_api/microsoft_auth_api_dummy_values.dart';

void main() {
  late MockMicrosoftAuthApi mockMicrosoftAuthApi;
  late _MockHttpServer mockHttpServer;

  late MicrosoftAuthCodeFlow flow;

  setUp(() {
    mockMicrosoftAuthApi = MockMicrosoftAuthApi();
    mockHttpServer = _MockHttpServer();
    flow = MicrosoftAuthCodeFlow(
      microsoftAuthApi: mockMicrosoftAuthApi,
      httpServerFactory: (_, _) async => mockHttpServer,
    );

    when(() => mockHttpServer.close()).thenAnswer((_) async {
      return null;
    });

    when(
      () => mockMicrosoftAuthApi.userLoginUrlWithAuthCode(),
    ).thenReturn(TestConstants.anyString);
    when(
      () => mockMicrosoftAuthApi.exchangeAuthCodeForTokens(any()),
    ).thenAnswer((_) async => dummyMicrosoftOAuthTokenResponse);
  });

  test(
    'httpServer is initially null before server is started',
    () => expect(flow.httpServer, null),
  );

  group('requireServer', () {
    test('throws $StateError if server has not been started', () {
      expect(() => flow.requireServer, throwsStateError);
    });

    test('returns running server instance if already started', () async {
      final server = await flow.startServer();
      expect(flow.requireServer, server);
    });
  });

  group('isServerRunning', () {
    test('returns true when server is running', () async {
      await flow.startServer();
      expect(flow.isServerRunning, true);
    });
    test('returns false when server is not running', () async {
      await flow.startServer();
      await flow.stopServer();
      expect(flow.isServerRunning, false);
    });
  });

  group('startServer', () {
    test('throws $AssertionError if it is already running', () async {
      await flow.startServer();
      await expectLater(flow.startServer(), throwsA(isA<AssertionError>()));
    });
    test('sets httpServer to not null', () async {
      expect(await flow.startServer(), flow.httpServer);
      expect(flow.httpServer, isNotNull);
    });

    test(
      'uses ${InternetAddress.loopbackIPv4} for the internet address',
      () async {
        InternetAddress? capturedInternetAddress;

        await MicrosoftAuthCodeFlow(
          microsoftAuthApi: mockMicrosoftAuthApi,
          httpServerFactory: (address, _) async {
            capturedInternetAddress = address;
            return mockHttpServer;
          },
        ).startServer();

        expect(capturedInternetAddress, InternetAddress.loopbackIPv4);
      },
    );

    test('uses the correct port', () async {
      int? capturedPort;

      await MicrosoftAuthCodeFlow(
        microsoftAuthApi: mockMicrosoftAuthApi,
        httpServerFactory: (_, port) async {
          capturedPort = port;
          return mockHttpServer;
        },
      ).startServer();

      expect(capturedPort, ProjectInfoConstants.microsoftLoginRedirectPort);
    });
  });

  group('stopServer', () {
    test('throws $AssertionError when stopping a non-running server', () async {
      await expectLater(flow.stopServer(), throwsA(isA<AssertionError>()));
    });

    test('calls close() on the running $HttpServer instance', () async {
      await flow.startServer();
      await flow.stopServer();

      verify(() => mockHttpServer.close()).called(1);
      verifyNoMoreInteractions(mockHttpServer);
    });

    test('sets httpServer to null after stopping a running server', () async {
      await flow.startServer();
      await flow.stopServer();
      expect(flow.httpServer, null);
    });
  });

  group('stopServerIfRunning', () {
    test('returns true and stops server when running', () async {
      await flow.startServer();

      expect(await flow.stopServerIfRunning(), true);
    });
    test('returns false and does nothing when server is not running', () async {
      expect(await flow.stopServerIfRunning(), false);
    });

    test('calls close() on the running $HttpServer instance', () async {
      await flow.startServer();
      await flow.stopServerIfRunning();

      verify(() => mockHttpServer.close()).called(1);
      verifyNoMoreInteractions(mockHttpServer);
    });
  });

  group('run', () {
    MicrosoftAuthCodeResponsePageContent authCodeResponsePageContent({
      String pageTitle = TestConstants.anyString,
      String title = TestConstants.anyString,
      String subtitle = TestConstants.anyString,
      String pageLangCode = TestConstants.anyString,
      String pageDir = TestConstants.anyString,
    }) => MicrosoftAuthCodeResponsePageContent(
      pageTitle: pageTitle,
      title: title,
      subtitle: subtitle,
      pageLangCode: pageLangCode,
      pageDir: pageDir,
    );

    MicrosoftAuthCodeResponsePageVariants authCodeResponsePageVariants({
      MicrosoftAuthCodeResponsePageContent? approved,
      MicrosoftAuthCodeResponsePageContent? accessDenied,
      MicrosoftAuthCodeResponsePageContent? missingAuthCode,
      MicrosoftAuthCodeResponsePageContent Function(
        String errorCode,
        String errorDescription,
      )?
      unknownError,
    }) => MicrosoftAuthCodeResponsePageVariants(
      accessDenied: accessDenied ?? authCodeResponsePageContent(),
      approved: approved ?? authCodeResponsePageContent(),
      missingAuthCode: missingAuthCode ?? authCodeResponsePageContent(),
      unknownError:
          unknownError ??
          (errorCode, errorDescription) => authCodeResponsePageContent(),
    );

    Future<MicrosoftOAuthTokenResponse?> run({
      AuthCodeProgressCallback? onProgress,
      AuthCodeLoginUrlAvailableCallback? onAuthCodeLoginUrlAvailable,
      MicrosoftAuthCodeResponsePageVariants? responsePageVariants,
    }) => flow.run(
      onProgress: onProgress ?? (_) {},
      onAuthCodeLoginUrlAvailable: onAuthCodeLoginUrlAvailable ?? (_) {},
      authCodeResponsePageVariants:
          responsePageVariants ?? authCodeResponsePageVariants(),
    );

    Future<void> withHttpRequest(
      HttpRequest request,
      Future<void> Function() run,
    ) async {
      final controller = StreamController<HttpRequest>();
      when(
        () => mockHttpServer.listen(
          any(),
          cancelOnError: any(named: 'cancelOnError'),
          onDone: any(named: 'onDone'),
          onError: any(named: 'onError'),
        ),
      ).thenAnswer((invocation) {
        final onData =
            invocation.positionalArguments[0] as void Function(HttpRequest);
        final onDone = invocation.namedArguments[#onDone] as void Function()?;
        final onError = invocation.namedArguments[#onError] as Function?;
        final cancelOnError =
            invocation.namedArguments[#cancelOnError] as bool?;

        final subscription = controller.stream.listen(
          onData,
          onDone: onDone,
          onError: onError,
          cancelOnError: cancelOnError ?? false,
        );

        // Emit the request after listener is ready
        scheduleMicrotask(() {
          controller.add(request);
        });

        return subscription;
      });

      try {
        await run();
      } finally {
        await controller.close();
      }
    }

    const fakeAuthCode = 'example-microsoft-auth-code';

    Future<
      (MicrosoftOAuthTokenResponse? tokenResponse, String? redirectPageHtml)
    >
    simulateAuthCodeRedirect({
      String? authCode = fakeAuthCode,
      String? errorCode,
      String? errorDescription,
      AuthCodeProgressCallback? onProgress,
      AuthCodeLoginUrlAvailableCallback? onAuthCodeLoginUrlAvailable,
      MicrosoftAuthCodeResponsePageVariants? authCodeResponsePageVariants,

      /// If `true`, swallow auth code flow failures and return `null` for token response instead of throwing.
      /// Useful to validate HTML responses in different cases when the token response is irrelevant.
      bool ignoreFailures = false,
      void Function({
        required _MockHttpResponse mockHttpResponse,
        required _MockHttpHeaders mockHttpHeaders,
      })?
      onMocksProvided,
    }) async {
      MicrosoftOAuthTokenResponse? tokenResponse;
      String? redirectPageHtml;

      final mockHttpRequest = _MockHttpRequest();
      when(() => mockHttpRequest.uri).thenReturn(
        Uri(
          queryParameters: {
            if (authCode != null)
              MicrosoftConstants.loginRedirectAuthCodeQueryParamName: authCode,
            if (errorCode != null)
              MicrosoftConstants.loginRedirectErrorQueryParamName: errorCode,
            if (errorDescription != null)
              MicrosoftConstants.loginRedirectErrorDescriptionQueryParamName:
                  errorDescription,
          },
        ),
      );

      final mockResponse = _MockHttpResponse();
      final mockHeaders = _MockHttpHeaders();

      when(() => mockResponse.write(any())).thenAnswer((invocation) {
        redirectPageHtml = invocation.positionalArguments[0] as String?;
      });
      when(() => mockResponse.close()).thenAnswer((_) async {
        return null;
      });
      when(() => mockResponse.headers).thenReturn(mockHeaders);

      when(() => mockHttpRequest.response).thenReturn(mockResponse);

      await flow.startServer();
      await withHttpRequest(mockHttpRequest, () async {
        if (ignoreFailures) {
          try {
            tokenResponse = await run(
              onProgress: onProgress,
              responsePageVariants: authCodeResponsePageVariants,
              onAuthCodeLoginUrlAvailable: onAuthCodeLoginUrlAvailable,
            );
          } on Exception catch (_) {
            // Ignore failures and keep tokenResponse null.
          }
        } else {
          tokenResponse = await run(
            onProgress: onProgress,
            responsePageVariants: authCodeResponsePageVariants,
            onAuthCodeLoginUrlAvailable: onAuthCodeLoginUrlAvailable,
          );
        }
      });

      onMocksProvided?.call(
        mockHttpHeaders: mockHeaders,
        mockHttpResponse: mockResponse,
      );

      return (tokenResponse, redirectPageHtml);
    }

    test('throws $StateError if server is not already running', () async {
      expect(
        flow.isServerRunning,
        false,
        reason: 'The server should not be running initially',
      );

      await expectLater(run(), throwsStateError);
    });

    test(
      'calls onProgress with ${MicrosoftAuthCodeProgress.waitingForUserLogin}',
      () async {
        bool progressCallbackCalled = false;
        final progressEvents = <MicrosoftAuthCodeProgress>[];

        await simulateAuthCodeRedirect(
          onProgress: (progress) {
            progressEvents.add(progress);
            progressCallbackCalled = true;
          },
        );

        if (!progressCallbackCalled) {
          throw StateError(
            'onProgress callback was not called; this likely indicates a test bug.',
          );
        }

        expect(
          progressEvents.first,
          MicrosoftAuthCodeProgress.waitingForUserLogin,
          reason:
              'Should call onProgress first with ${MicrosoftAuthCodeProgress.waitingForUserLogin.name}.',
        );
      },
    );

    test(
      'calls onAuthCodeLoginUrlAvailable with the correct login URL',
      () async {
        const expectedUrl = 'https://example.com/login/oauth2/callback';

        when(
          () => mockMicrosoftAuthApi.userLoginUrlWithAuthCode(),
        ).thenReturn(expectedUrl);

        String? actualUrl;
        bool urlCallbackCalled = false;

        await simulateAuthCodeRedirect(
          onAuthCodeLoginUrlAvailable: (authCodeLoginUrl) {
            actualUrl = authCodeLoginUrl;
            urlCallbackCalled = true;
          },
        );

        if (!urlCallbackCalled) {
          throw StateError(
            'onAuthCodeLoginUrlAvailable callback was not called; this likely indicates a test bug.',
          );
        }

        expect(actualUrl, expectedUrl);
      },
    );

    test(
      'closes response and server and responds with correct status code and headers',
      () async {
        // This test covers common behavior regardless of success or failure.
        // Specific HTML content is tested separately.

        bool called = false;
        await simulateAuthCodeRedirect(
          onMocksProvided: ({
            required mockHttpHeaders,
            required mockHttpResponse,
          }) {
            verify(
              () => mockHttpHeaders.contentType = ContentType.html,
            ).called(1);
            verifyNoMoreInteractions(mockHttpHeaders);

            verify(() => mockHttpResponse.close()).called(1);
            verify(() => mockHttpResponse.statusCode = HttpStatus.ok).called(1);
            verify(() => mockHttpResponse.write(any())).called(1);
            verify(() => mockHttpResponse.headers).called(1);
            verifyNoMoreInteractions(mockHttpResponse);

            expect(
              flow.isServerRunning,
              false,
              reason: 'The server should not be running.',
            );

            called = true;
          },
        );
        if (!called) {
          throw StateError(
            'onProvideMocks callback was not called; this likely indicates a test bug.',
          );
        }
      },
    );

    // START: Unknown redirect errors

    test(
      'returns unknown error HTML page and stops server on unrecognized redirect error code',
      () async {
        const unknownErrorCode = 'unknown_error';
        const unknownErrorDescription = 'An internal server error';

        final pageContent = authCodeResponsePageContent(
          title: 'An error occurred',
          pageDir: 'rtl',
          pageLangCode: 'de',
          pageTitle: 'An unknown error occurred',
          subtitle:
              'An unknown error occurred while logging in: $unknownErrorCode, $unknownErrorDescription',
        );

        final (_, response) = await simulateAuthCodeRedirect(
          errorCode: unknownErrorCode,
          errorDescription: unknownErrorDescription,
          authCodeResponsePageVariants: authCodeResponsePageVariants(
            unknownError: (errorCode, errorDescription) => pageContent,
          ),
          ignoreFailures: true,
        );

        expect(flow.isServerRunning, false);

        expect(
          response,
          buildAuthCodeResultHtmlPage(pageContent, isSuccess: false),
        );
      },
    );

    test(
      'throws ${microsoft_auth_code_flow_exceptions.AuthCodeRedirectException} for unrecognized redirect error code',
      () async {
        const unknownErrorCode = 'unknown_error';
        const unknownErrorDescription = 'An internal server error';

        await expectLater(
          simulateAuthCodeRedirect(
            authCode: null,
            errorCode: unknownErrorCode,
            errorDescription: unknownErrorDescription,
          ),
          throwsA(
            isA<microsoft_auth_code_flow_exceptions.AuthCodeRedirectException>()
                .having((e) => e.error, 'errorCode', unknownErrorCode)
                .having(
                  (e) => e.errorDescription,
                  'errorDescription',
                  unknownErrorDescription,
                ),
          ),
        );

        expect(flow.isServerRunning, false);
      },
    );

    // END: Unknown redirect errors

    // START: Auth code missing redirect error

    test(
      'returns missing auth code HTML page and stops server when auth code query parameter is absent',
      () async {
        final pageContent = authCodeResponsePageContent(
          title: 'The auth code query parameter is missing',
          pageDir: 'ltr',
          pageLangCode: 'zh',
          pageTitle: 'Auth code is missing',
          subtitle: 'Please restart the sign-in process.',
        );

        final (_, response) = await simulateAuthCodeRedirect(
          authCode: null,
          authCodeResponsePageVariants: authCodeResponsePageVariants(
            missingAuthCode: pageContent,
          ),
          ignoreFailures: true,
        );

        expect(flow.isServerRunning, false);

        expect(
          response,
          buildAuthCodeResultHtmlPage(pageContent, isSuccess: false),
        );
      },
    );

    test(
      'throws ${microsoft_auth_code_flow_exceptions.AuthCodeMissingException} when redirect code query parameter is absent',
      () async {
        await expectLater(
          simulateAuthCodeRedirect(authCode: null),
          throwsA(
            isA<microsoft_auth_code_flow_exceptions.AuthCodeMissingException>(),
          ),
        );
        expect(flow.isServerRunning, false);
      },
    );

    // END: Auth code missing redirect error

    // START: Access denied redirect error

    test(
      'returns access denied HTML page and stops server when redirect error query parameter is ${MicrosoftConstants.loginRedirectAccessDeniedErrorCode}',
      () async {
        final pageContent = authCodeResponsePageContent(
          title: 'The auth code query parameter is missing',
          pageDir: 'ltr',
          pageLangCode: 'zh',
          pageTitle: 'Auth code is missing',
          subtitle: 'Please restart the sign-in process.',
        );

        final (_, response) = await simulateAuthCodeRedirect(
          authCode: null,
          errorCode: MicrosoftConstants.loginRedirectAccessDeniedErrorCode,
          authCodeResponsePageVariants: authCodeResponsePageVariants(
            accessDenied: pageContent,
          ),
          ignoreFailures: true,
        );

        expect(flow.isServerRunning, false);

        expect(
          response,
          buildAuthCodeResultHtmlPage(pageContent, isSuccess: false),
        );
      },
    );

    test(
      'throws ${microsoft_auth_code_flow_exceptions.AuthCodeDeniedException} when redirect error query parameter is ${MicrosoftConstants.loginRedirectAccessDeniedErrorCode}',
      () async {
        await expectLater(
          simulateAuthCodeRedirect(
            authCode: null,
            errorCode: MicrosoftConstants.loginRedirectAccessDeniedErrorCode,
          ),
          throwsA(
            isA<microsoft_auth_code_flow_exceptions.AuthCodeDeniedException>(),
          ),
        );
        expect(flow.isServerRunning, false);
      },
    );

    // END: Access denied redirect error

    test(
      'responds with success HTML page and closes server on success',
      () async {
        final pageContent = authCodeResponsePageContent(
          title: 'You are logged in now!',
          pageDir: 'ltr',
          pageLangCode: 'en',
          pageTitle: 'Successful Login!',
          subtitle:
              'You can close this window now, the launcher is logging in...',
        );

        final (_, response) = await simulateAuthCodeRedirect(
          authCode: fakeAuthCode,
          authCodeResponsePageVariants: authCodeResponsePageVariants(
            approved: pageContent,
          ),
        );

        expect(flow.isServerRunning, false);

        expect(
          response,
          buildAuthCodeResultHtmlPage(pageContent, isSuccess: true),
        );
      },
    );

    test(
      'calls onProgress with ${MicrosoftAuthCodeProgress.exchangingAuthCode}',
      () async {
        final progressEvents = <MicrosoftAuthCodeProgress>[];
        bool progressCallbackCalled = false;

        final (_, _) = await simulateAuthCodeRedirect(
          onProgress: (progress) {
            progressEvents.add(progress);
            progressCallbackCalled = true;
          },
        );

        if (!progressCallbackCalled) {
          throw StateError(
            'onProgress callback was not called; this likely indicates a test bug.',
          );
        }

        expect(progressEvents, [
          MicrosoftAuthCodeProgress.waitingForUserLogin,
          MicrosoftAuthCodeProgress.exchangingAuthCode,
        ]);
      },
    );

    test('passes auth code correctly to $MicrosoftAuthApi', () async {
      final (_, _) = await simulateAuthCodeRedirect(authCode: fakeAuthCode);

      verify(
        () => mockMicrosoftAuthApi.exchangeAuthCodeForTokens(
          any(that: equals(fakeAuthCode)),
        ),
      ).called(1);
    });

    test(
      'does not interact with unrelated $MicrosoftAuthApi methods',
      () async {
        final (_, _) = await simulateAuthCodeRedirect();

        verifyInOrder([
          () => mockMicrosoftAuthApi.userLoginUrlWithAuthCode(),
          () => mockMicrosoftAuthApi.exchangeAuthCodeForTokens(any()),
        ]);
        verifyNoMoreInteractions(mockMicrosoftAuthApi);
      },
    );

    test(
      'returns $MicrosoftOAuthTokenResponse correctly from $MicrosoftAuthApi',
      () async {
        const expectedTokenResponse = MicrosoftOAuthTokenResponse(
          accessToken: 'example-microsoft-oauth-token',
          expiresIn: 3600,
          refreshToken: 'example-microsoft-oauth-refresh-token',
        );
        when(
          () => mockMicrosoftAuthApi.exchangeAuthCodeForTokens(any()),
        ).thenAnswer((_) async => expectedTokenResponse);

        final (actualTokenResponse, _) = await simulateAuthCodeRedirect();

        expect(actualTokenResponse, same(expectedTokenResponse));
      },
    );
  });
}

class _MockHttpServer extends Mock implements HttpServer {}

class _MockHttpRequest extends Mock implements HttpRequest {}

class _MockHttpResponse extends Mock implements HttpResponse {}

class _MockHttpHeaders extends Mock implements HttpHeaders {}
