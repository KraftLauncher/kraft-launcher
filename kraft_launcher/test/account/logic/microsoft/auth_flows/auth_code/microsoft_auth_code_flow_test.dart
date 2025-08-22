import 'package:kraft_launcher/account/data/microsoft_auth_api/microsoft_auth_api.dart';
import 'package:kraft_launcher/account/data/redirect_http_server_handler/redirect_http_server_handler.dart';
import 'package:kraft_launcher/account/data/redirect_http_server_handler/redirect_http_server_handler_failures.dart';
import 'package:kraft_launcher/account/logic/microsoft/auth_flows/auth_code/microsoft_auth_code_flow.dart';
import 'package:kraft_launcher/account/logic/microsoft/auth_flows/auth_code/microsoft_auth_code_flow_exceptions.dart'
    as microsoft_auth_code_flow_exceptions;
import 'package:kraft_launcher/common/constants/constants.dart';
import 'package:kraft_launcher/common/functional/result.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../../common/helpers/mocks.dart';
import '../../../../../common/test_constants.dart';
import '../../../../data/microsoft_auth_api/microsoft_auth_api_dummy_values.dart';

void main() {
  late MockMicrosoftAuthApi mockMicrosoftAuthApi;
  late _MockRedirectHttpServerHandler mockRedirectHttpServerHandler;

  late MicrosoftAuthCodeFlow flow;

  setUp(() {
    mockMicrosoftAuthApi = MockMicrosoftAuthApi();
    mockRedirectHttpServerHandler = _MockRedirectHttpServerHandler();

    flow = MicrosoftAuthCodeFlow(
      microsoftAuthApi: mockMicrosoftAuthApi,
      redirectHttpServerHandler: mockRedirectHttpServerHandler,
    );

    when(() => mockRedirectHttpServerHandler.close()).thenAnswer((_) async {});

    when(
      () => mockMicrosoftAuthApi.userLoginUrlWithAuthCode(),
    ).thenReturn(TestConstants.anyString);
    when(
      () => mockMicrosoftAuthApi.exchangeAuthCodeForTokens(any()),
    ).thenAnswer((_) async => dummyMicrosoftOAuthTokenResponse);
  });

  group('closeServer', () {
    test('returns true when server is running', () async {
      when(() => mockRedirectHttpServerHandler.isRunning).thenReturn(true);

      expect(await flow.closeServer(), true);
    });
    test('closes the server when running', () async {
      when(() => mockRedirectHttpServerHandler.isRunning).thenReturn(true);

      await flow.closeServer();

      verify(() => mockRedirectHttpServerHandler.close()).called(1);
    });

    test(
      'returns false and does not attempt to close when server is not running',
      () async {
        when(() => mockRedirectHttpServerHandler.isRunning).thenReturn(false);

        expect(await flow.closeServer(), false);

        verifyNever(() => mockRedirectHttpServerHandler.close());
      },
    );

    test('interacts with $RedirectHttpServerHandler correctly', () async {
      for (final isRunning in {true, false}) {
        when(
          () => mockRedirectHttpServerHandler.isRunning,
        ).thenReturn(isRunning);

        await flow.closeServer();

        verify(() => mockRedirectHttpServerHandler.isRunning).called(1);

        if (isRunning) {
          verify(() => mockRedirectHttpServerHandler.close()).called(1);
        } else {
          verifyNever(() => mockRedirectHttpServerHandler.close());
        }

        verifyNoMoreInteractions(mockRedirectHttpServerHandler);
      }
    });
  });

  group('run', () {
    setUp(() {
      when(() => mockRedirectHttpServerHandler.isRunning).thenReturn(false);
    });

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

    const fakeAuthCode = 'example-microsoft-auth-code';

    Future<MicrosoftOAuthTokenResponse?> simulateAuthCodeRedirect({
      String? authCode = fakeAuthCode,
      String? errorCode,
      String? errorDescription,
      AuthCodeProgressCallback? onProgress,
      AuthCodeLoginUrlAvailableCallback? onAuthCodeLoginUrlAvailable,
      MicrosoftAuthCodeResponsePageVariants? authCodeResponsePageVariants,

      /// If `true`, swallow auth code flow failures and return `null` for token response instead of throwing.
      /// Useful to validate HTML responses in different cases when the token response is irrelevant.
      bool ignoreFailures = false,
    }) async {
      MicrosoftOAuthTokenResponse? tokenResponse;

      when(() => mockRedirectHttpServerHandler.waitForRequest()).thenAnswer(
        (_) async => {
          if (authCode != null)
            MicrosoftConstants.loginRedirectAuthCodeQueryParamName: authCode,
          if (errorCode != null)
            MicrosoftConstants.loginRedirectErrorQueryParamName: errorCode,
          if (errorDescription != null)
            MicrosoftConstants.loginRedirectErrorDescriptionQueryParamName:
                errorDescription,
        },
      );

      when(
        () => mockRedirectHttpServerHandler.respondAndClose(any()),
      ).thenAnswer((invocation) async {});

      when(() => mockRedirectHttpServerHandler.isRunning).thenReturn(false);

      when(
        () => mockRedirectHttpServerHandler.start(port: any(named: 'port')),
      ).thenAnswer((_) async => Result.emptySuccess());

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

      return tokenResponse;
    }

    test('throws $StateError when server is already running', () async {
      when(() => mockRedirectHttpServerHandler.isRunning).thenReturn(true);

      await expectLater(run(), throwsStateError);
    });

    test(
      'throws ${microsoft_auth_code_flow_exceptions.AuthCodeServerStartException} when $RedirectHttpServerHandler returns a failure',
      () async {
        // Avoid const to ensure unique instance for reference equality in test when using same().
        // ignore: prefer_const_constructors
        final failure = PortInUseFailure(TestConstants.anyInt);
        when(
          () => mockRedirectHttpServerHandler.start(port: any(named: 'port')),
        ).thenAnswer((_) async => Result.failure(failure));

        await expectLater(
          run(),
          throwsA(
            isA<
                  microsoft_auth_code_flow_exceptions.AuthCodeServerStartException
                >()
                .having((e) => e.failure, 'failure', same(failure)),
          ),
        );
      },
    );

    test('starts the redirect HTTP server when it is not running', () async {
      await simulateAuthCodeRedirect();
      verify(
        () => mockRedirectHttpServerHandler.start(port: any(named: 'port')),
      ).called(1);
    });

    test('uses the expected port when starting the HTTP server', () async {
      const expectedPort = MicrosoftAuthCodeFlow.serverPort;

      await simulateAuthCodeRedirect();
      verify(
        () => mockRedirectHttpServerHandler.start(
          port: any(named: 'port', that: equals(expectedPort)),
        ),
      ).called(1);
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

    // START: Unknown redirect errors

    test(
      'responds with unknown error HTML page and stops server on unrecognized redirect error code',
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

        await simulateAuthCodeRedirect(
          errorCode: unknownErrorCode,
          errorDescription: unknownErrorDescription,
          authCodeResponsePageVariants: authCodeResponsePageVariants(
            unknownError: (errorCode, errorDescription) => pageContent,
          ),
          ignoreFailures: true,
        );

        final expectedResponse = buildAuthCodeResultHtmlPage(
          pageContent,
          isSuccess: false,
        );

        verify(
          () => mockRedirectHttpServerHandler.respondAndClose(expectedResponse),
        ).called(1);
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
      },
    );

    // END: Unknown redirect errors

    // START: Auth code missing redirect error

    test(
      'responds with missing auth code HTML page and stops server when auth code query parameter is absent',
      () async {
        final pageContent = authCodeResponsePageContent(
          title: 'The auth code query parameter is missing',
          pageDir: 'ltr',
          pageLangCode: 'zh',
          pageTitle: 'Auth code is missing',
          subtitle: 'Please restart the sign-in process.',
        );

        await simulateAuthCodeRedirect(
          authCode: null,
          authCodeResponsePageVariants: authCodeResponsePageVariants(
            missingAuthCode: pageContent,
          ),
          ignoreFailures: true,
        );

        final expectedResponse = buildAuthCodeResultHtmlPage(
          pageContent,
          isSuccess: false,
        );

        verify(
          () => mockRedirectHttpServerHandler.respondAndClose(expectedResponse),
        ).called(1);
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
      },
    );

    // END: Auth code missing redirect error

    // START: Access denied redirect error

    test(
      'responds with access denied HTML page and stops server when redirect error query parameter is ${MicrosoftConstants.loginRedirectAccessDeniedErrorCode}',
      () async {
        final pageContent = authCodeResponsePageContent(
          title: 'The auth code query parameter is missing',
          pageDir: 'ltr',
          pageLangCode: 'zh',
          pageTitle: 'Auth code is missing',
          subtitle: 'Please restart the sign-in process.',
        );

        await simulateAuthCodeRedirect(
          authCode: null,
          errorCode: MicrosoftConstants.loginRedirectAccessDeniedErrorCode,
          authCodeResponsePageVariants: authCodeResponsePageVariants(
            accessDenied: pageContent,
          ),
          ignoreFailures: true,
        );

        final expectedResponse = buildAuthCodeResultHtmlPage(
          pageContent,
          isSuccess: false,
        );

        verify(
          () => mockRedirectHttpServerHandler.respondAndClose(expectedResponse),
        ).called(1);
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

        await simulateAuthCodeRedirect(
          authCode: fakeAuthCode,
          authCodeResponsePageVariants: authCodeResponsePageVariants(
            approved: pageContent,
          ),
        );

        final expectedResponse = buildAuthCodeResultHtmlPage(
          pageContent,
          isSuccess: true,
        );

        verify(
          () => mockRedirectHttpServerHandler.respondAndClose(expectedResponse),
        ).called(1);
      },
    );

    test(
      'calls onProgress with ${MicrosoftAuthCodeProgress.exchangingAuthCode}',
      () async {
        final progressEvents = <MicrosoftAuthCodeProgress>[];
        bool progressCallbackCalled = false;

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

        expect(progressEvents, [
          MicrosoftAuthCodeProgress.waitingForUserLogin,
          MicrosoftAuthCodeProgress.exchangingAuthCode,
        ]);
      },
    );

    test('passes auth code correctly to $MicrosoftAuthApi', () async {
      await simulateAuthCodeRedirect(authCode: fakeAuthCode);

      verify(
        () => mockMicrosoftAuthApi.exchangeAuthCodeForTokens(
          any(that: equals(fakeAuthCode)),
        ),
      ).called(1);
    });

    test(
      'does not interact with unrelated $MicrosoftAuthApi methods',
      () async {
        await simulateAuthCodeRedirect();

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

        final actualTokenResponse = await simulateAuthCodeRedirect();

        expect(actualTokenResponse, same(expectedTokenResponse));
      },
    );

    test('interacts with $RedirectHttpServerHandler correctly', () async {
      await simulateAuthCodeRedirect();

      verify(() => mockRedirectHttpServerHandler.isRunning).called(1);
      verify(
        () => mockRedirectHttpServerHandler.start(port: any(named: 'port')),
      ).called(1);
      verify(() => mockRedirectHttpServerHandler.waitForRequest()).called(1);
      verify(
        () => mockRedirectHttpServerHandler.respondAndClose(any()),
      ).called(1);
      verifyNoMoreInteractions(mockRedirectHttpServerHandler);
    });
  });
}

class _MockRedirectHttpServerHandler extends Mock
    implements RedirectHttpServerHandler {}
