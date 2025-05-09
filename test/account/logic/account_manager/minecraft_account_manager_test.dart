import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:kraft_launcher/account/data/account_storage/account_storage.dart';
import 'package:kraft_launcher/account/data/microsoft_auth_api/auth_methods/microsoft_device_code_flow.dart';
import 'package:kraft_launcher/account/data/microsoft_auth_api/microsoft_auth_api.dart';
import 'package:kraft_launcher/account/data/microsoft_auth_api/microsoft_auth_exceptions.dart'
    show MicrosoftAuthException;
import 'package:kraft_launcher/account/data/minecraft_account.dart';
import 'package:kraft_launcher/account/data/minecraft_accounts.dart';
import 'package:kraft_launcher/account/data/minecraft_api/minecraft_api.dart';
import 'package:kraft_launcher/account/data/minecraft_api/minecraft_api_exceptions.dart'
    show MinecraftApiException;
import 'package:kraft_launcher/account/logic/account_manager/async_timer.dart';
import 'package:kraft_launcher/account/logic/account_manager/image_cache_service/image_cache_service.dart';
import 'package:kraft_launcher/account/logic/account_manager/minecraft_account_manager.dart';
import 'package:kraft_launcher/account/logic/account_manager/minecraft_account_manager_exceptions.dart';
import 'package:kraft_launcher/account/logic/minecraft_skin_ext.dart';
import 'package:kraft_launcher/common/constants/constants.dart';
import 'package:kraft_launcher/common/logic/dio_client.dart';
import 'package:kraft_launcher/common/logic/json.dart';
import 'package:kraft_launcher/common/logic/utils.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../../common/helpers/dio_utils.dart';
import '../../../common/helpers/url_launcher_utils.dart';
import '../../../common/helpers/utils.dart';

class MockMicrosoftAuthApi extends Mock implements MicrosoftAuthApi {}

class MockMinecraftApi extends Mock implements MinecraftApi {}

class MockAccountStorage extends Mock implements AccountStorage {}

void main() {
  late MockMicrosoftAuthApi mockMicrosoftAuthApi;
  late MockMinecraftApi mockMinecraftApi;
  late MinecraftAccountManager minecraftAccountManager;
  late MockAccountStorage mockAccountStorage;
  late MockImageCacheService mockImageCacheService;

  setUp(() {
    mockMicrosoftAuthApi = MockMicrosoftAuthApi();
    mockMinecraftApi = MockMinecraftApi();
    mockAccountStorage = MockAccountStorage();
    mockImageCacheService = MockImageCacheService();
    minecraftAccountManager = MinecraftAccountManager(
      minecraftApi: mockMinecraftApi,
      microsoftAuthApi: mockMicrosoftAuthApi,
      accountStorage: mockAccountStorage,
      imageCacheService: mockImageCacheService,
    );

    when(
      () => mockAccountStorage.loadAccounts(),
    ).thenReturn(MinecraftAccounts.empty());

    when(() => mockAccountStorage.saveAccounts(any())).thenDoNothing();

    when(() => mockMicrosoftAuthApi.requestXboxLiveToken(any())).thenAnswer(
      (_) async => const XboxLiveAuthTokenResponse(xboxToken: '', userHash: ''),
    );
    when(() => mockMicrosoftAuthApi.requestXSTSToken(any())).thenAnswer(
      (_) async => const XboxLiveAuthTokenResponse(xboxToken: '', userHash: ''),
    );
    when(
      () => mockMinecraftApi.checkMinecraftJavaOwnership(any()),
    ).thenAnswer((_) async => false);
    when(() => mockMinecraftApi.fetchMinecraftProfile(any())).thenAnswer(
      (_) async => const MinecraftProfileResponse(
        id: '',
        name: '',
        skins: [],
        capes: [],
      ),
    );
    when(() => mockMinecraftApi.loginToMinecraftWithXbox(any())).thenAnswer(
      (_) async => const MinecraftLoginResponse(
        username: '',
        accessToken: '',
        expiresIn: -1,
      ),
    );
  });

  // Mock the new account that will be returned from the APIs whether it's
  // using device code, auth code or refreshing the account. This will mock the API
  // responses that are used to build the Minecraft account and always assumes success.
  void mockMinecraftAccountAsLoginResult(
    MinecraftAccount account, {
    bool isAuthCode = false,
    bool isDeviceCode = false,
    bool isRefreshAccount = false,
  }) {
    when(() => mockMinecraftApi.fetchMinecraftProfile(any())).thenAnswer(
      (_) async => MinecraftProfileResponse(
        id: account.id,
        name: account.username,
        skins:
            account.skins
                .map(
                  (skin) => MinecraftProfileSkin(
                    id: skin.id,
                    state: skin.state,
                    textureKey: skin.textureKey,
                    url: skin.url,
                    variant: skin.variant,
                  ),
                )
                .toList(),
        // The launcher doesn't support managing capes yet.
        capes: const [],
      ),
    );

    when(
      () => mockMinecraftApi.checkMinecraftJavaOwnership(any()),
    ).thenAnswer((_) async => account.ownsMinecraftJava ?? false);
    when(() => mockMinecraftApi.loginToMinecraftWithXbox(any())).thenAnswer(
      (_) async => MinecraftLoginResponse(
        accessToken:
            account.microsoftAccountInfo?.minecraftAccessToken.value ??
            (fail('Please provide a value for minecraft access token')),
        username: account.username,
        expiresIn:
            account
                .microsoftAccountInfo
                ?.minecraftAccessToken
                .expiresAt
                .covertToExpiresIn ??
            (fail(
              'Please provide a value for minecraft access token expires in',
            )),
      ),
    );

    MicrosoftOauthTokenExchangeResponse
    response() => MicrosoftOauthTokenExchangeResponse(
      accessToken:
          account.microsoftAccountInfo?.microsoftOAuthAccessToken.value ??
          (fail('Please provide a value for Microsoft OAuth access token')),
      refreshToken:
          account.microsoftAccountInfo?.microsoftOAuthRefreshToken ??
          (fail('Please provide a value for Microsoft OAuth refresh token')),
      expiresIn:
          account
              .microsoftAccountInfo
              ?.microsoftOAuthAccessToken
              .expiresAt
              .covertToExpiresIn ??
          (fail(
            'Please provide a value for Microsoft OAuth access token expires in',
          )),
    );
    if (isAuthCode) {
      when(
        () => mockMicrosoftAuthApi.exchangeAuthCodeForTokens(any()),
      ).thenAnswer((_) async => response());
    }

    if (isRefreshAccount) {
      when(
        () => mockMicrosoftAuthApi.getNewTokensFromRefreshToken(any()),
      ).thenAnswer((_) async => response());
    }
    if (isDeviceCode) {
      when(() => mockMicrosoftAuthApi.checkDeviceCodeStatus(any())).thenAnswer(
        (_) async => MicrosoftCheckDeviceCodeStatusResult.approved(response()),
      );
    }
    if (!isAuthCode && !isRefreshAccount && !isDeviceCode) {
      fail(
        'Callers of mockMinecraftAccountAsLoginResult should declare whether this is for refreshing the account, login with auth code or device code.',
      );
    }
  }

  setUpAll(() {
    registerFallbackValue(MinecraftAccounts.empty());
    registerFallbackValue(
      const MicrosoftOauthTokenExchangeResponse(
        accessToken: '',
        expiresIn: -1,
        refreshToken: '',
      ),
    );
    registerFallbackValue(
      const XboxLiveAuthTokenResponse(userHash: '', xboxToken: ''),
    );
  });

  group('auth code flow', () {
    tearDown(() async {
      if (minecraftAccountManager.isServerRunning) {
        await minecraftAccountManager.stopServer();
      }
    });

    test('requireServer throws $StateError if null', () {
      expect(() => minecraftAccountManager.requireServer, throwsStateError);
    });

    test('requireServer returns httpServer if not null', () async {
      final server = await minecraftAccountManager.startServer();
      expect(minecraftAccountManager.requireServer, server);
    });

    test('isServerRunning returns correctly', () async {
      await minecraftAccountManager.startServer();
      expect(minecraftAccountManager.isServerRunning, true);

      await minecraftAccountManager.stopServer();
      expect(minecraftAccountManager.isServerRunning, false);
    });

    test(
      'httpServer initially null',
      () => expect(minecraftAccountManager.httpServer, null),
    );

    test('startServer sets httpServer to not null', () async {
      expect(
        await minecraftAccountManager.startServer(),
        minecraftAccountManager.httpServer,
      );
      expect(minecraftAccountManager.httpServer, isNotNull);
    });

    test('stopServer sets httpServer to null', () async {
      await minecraftAccountManager.startServer();
      await minecraftAccountManager.stopServer();
      expect(minecraftAccountManager.httpServer, null);
    });
    test('stopServerIfRunning stops the server if it is running', () async {
      await minecraftAccountManager.startServer();

      expect(await minecraftAccountManager.stopServerIfRunning(), true);
    });
    test('stopServerIfRunning do thing if', () async {
      expect(await minecraftAccountManager.stopServerIfRunning(), false);
    });

    (String, int) addressAndPort() => (
      minecraftAccountManager.requireServer.address.address,
      minecraftAccountManager.requireServer.port,
    );

    Uri serverUri({required String? codeCodeParam}) {
      final (address, port) = addressAndPort();
      return Uri.http('$address:$port', '/', {
        if (codeCodeParam != null)
          MicrosoftConstants.loginRedirectCodeQueryParamName: codeCodeParam,
      });
    }

    test('server is reachable when started', () async {
      await minecraftAccountManager.startServer();
      expect(minecraftAccountManager.isServerRunning, true);

      final (address, port) = addressAndPort();
      expect(await isPortOpen(address, port), true);
      await minecraftAccountManager.stopServer();
    });

    test('server is not reachable when stopped', () async {
      await minecraftAccountManager.startServer();

      final (address, port) = addressAndPort();

      await minecraftAccountManager.stopServer();
      expect(minecraftAccountManager.isServerRunning, false);

      expect(await isPortOpen(address, port), false);
    });

    group('loginWithMicrosoftAuthCode', () {
      // NOTE: These tests start a minimal localhost HTTP server and send
      // real GET requests to it. As a result, they're not pure unit tests.

      late MockUrlLauncher mockUrlLauncher;

      AuthCodeSuccessLoginPageContent successPageContent({
        String pageTitle = '',
        String title = '',
        String subtitle = '',
        String pageLangCode = '',
        String pageDir = '',
      }) => AuthCodeSuccessLoginPageContent(
        pageTitle: pageTitle,
        title: title,
        subtitle: subtitle,
        pageLangCode: pageLangCode,
        pageDir: pageDir,
      );

      setUpAll(() {
        registerFallbackValue(dummyLauncherOptions());
      });

      setUp(() {
        mockUrlLauncher = MockUrlLauncher();
        UrlLauncherPlatform.instance = mockUrlLauncher;
        when(
          () => mockUrlLauncher.launchUrl(any(), any()),
        ).thenAnswer((_) async => false);
        when(
          () => mockMicrosoftAuthApi.userLoginUrlWithAuthCode(),
        ).thenReturn('');
        when(
          () => mockMicrosoftAuthApi.exchangeAuthCodeForTokens(any()),
        ).thenAnswer(
          (_) async => const MicrosoftOauthTokenExchangeResponse(
            accessToken: '',
            expiresIn: -1,
            refreshToken: '',
          ),
        );
      });

      test('starts server if not started already', () async {
        expect(minecraftAccountManager.isServerRunning, false);

        unawaited(
          minecraftAccountManager.loginWithMicrosoftAuthCode(
            onProgressUpdate: (_, {authCodeLoginUrl}) {},
            successLoginPageContent: successPageContent(),
          ),
        );

        // Waiting for the server to start
        await Future<void>.delayed(Duration.zero);
        expect(minecraftAccountManager.isServerRunning, true);

        await minecraftAccountManager.stopServer();
      });

      test('opens the correct URL after starting the server', () async {
        const authCodeLoginUrl = 'https://example.com/login/oauth2/callback';

        when(
          () => mockUrlLauncher.launchUrl(authCodeLoginUrl, any()),
        ).thenAnswer((_) async => true);
        when(
          () => mockMicrosoftAuthApi.userLoginUrlWithAuthCode(),
        ).thenReturn(authCodeLoginUrl);

        unawaited(
          minecraftAccountManager.loginWithMicrosoftAuthCode(
            onProgressUpdate: (_, {authCodeLoginUrl}) {},
            successLoginPageContent: successPageContent(),
          ),
        );

        // Waiting for the server to start
        await Future<void>.delayed(Duration.zero);
        verify(
          () => mockUrlLauncher.launchUrl(authCodeLoginUrl, any()),
        ).called(1);
        verifyNoMoreInteractions(mockUrlLauncher);

        verify(() => mockMicrosoftAuthApi.userLoginUrlWithAuthCode()).called(1);
        verifyNoMoreInteractions(mockMicrosoftAuthApi);

        await minecraftAccountManager.stopServer();
      });

      test('calls onProgressUpdate with the login URL', () async {
        const authCodeLoginUrl = 'https://example.com/login/oauth2/callback';

        String? capturedLoginUrl;
        when(
          () => mockMicrosoftAuthApi.userLoginUrlWithAuthCode(),
        ).thenReturn(authCodeLoginUrl);

        unawaited(
          minecraftAccountManager.loginWithMicrosoftAuthCode(
            onProgressUpdate: (progress, {authCodeLoginUrl}) {
              capturedLoginUrl = authCodeLoginUrl;
              if (progress != MicrosoftAuthProgress.waitingForUserLogin) {
                fail(
                  'Expected the progress to be ${MicrosoftAuthProgress.waitingForUserLogin.name} as this state',
                );
              }
            },
            successLoginPageContent: successPageContent(),
          ),
        );

        // Waiting for the server to start
        await Future<void>.delayed(Duration.zero);

        expect(capturedLoginUrl, isNotNull);
        expect(capturedLoginUrl, authCodeLoginUrl);

        await minecraftAccountManager.stopServer();
      });

      test('cancels device code polling timer', () async {
        minecraftAccountManager.deviceCodePollingTimer = AsyncTimer.periodic(
          // This duration is a dummy value
          const Duration(seconds: 10),
          () {},
        );
        expect(minecraftAccountManager.isDeviceCodePollingTimerActive, true);
        expect(minecraftAccountManager.deviceCodePollingTimer, isNotNull);

        unawaited(
          minecraftAccountManager.loginWithMicrosoftAuthCode(
            onProgressUpdate: (_, {authCodeLoginUrl}) {},
            successLoginPageContent: successPageContent(),
          ),
        );
        // Waiting for the server to start
        await Future<void>.delayed(Duration.zero);

        expect(minecraftAccountManager.isDeviceCodePollingTimerActive, false);
        expect(minecraftAccountManager.deviceCodePollingTimer, isNull);
        expect(
          minecraftAccountManager.requestCancelDeviceCodePollingTimer,
          true,
        );

        await minecraftAccountManager.stopServer();
      });

      test(
        'throws $MissingAuthCodeAccountManagerException when code query param is missing',
        () async {
          unawaited(
            Future<void>.delayed(Duration.zero).then((_) async {
              await DioTestClient.instance.getUri<String>(
                serverUri(codeCodeParam: null),
              );
            }),
          );
          await expectLater(
            minecraftAccountManager.loginWithMicrosoftAuthCode(
              onProgressUpdate: (_, {authCodeLoginUrl}) {},
              successLoginPageContent: successPageContent(),
            ),
            throwsA(isA<MissingAuthCodeAccountManagerException>()),
          );
          expect(minecraftAccountManager.isServerRunning, false);
        },
      );

      const fakeAuthCode = 'M1ddasdasdsadsadsadsadsq0idqwjiod';

      // Starts the redirect server, sends an HTTP request to it with the auth code
      // as if the Microsoft API had redirected the user, and then returns the result.
      Future<(AccountResult? result, String? redirectServerResponse)>
      simulateAuthCodeRedirect({
        String authCode = fakeAuthCode,
        OnAuthProgressUpdateAuthCodeCallback? onProgressUpdate,
        AuthCodeSuccessLoginPageContent? successLoginPageContent,
      }) async {
        final getRequestCompleter = Completer<String?>();
        unawaited(
          Future<void>.delayed(Duration.zero).then((_) async {
            try {
              final response =
                  (await DioTestClient.instance.getUri<String>(
                    serverUri(codeCodeParam: fakeAuthCode),
                  )).dataOrThrow;
              getRequestCompleter.complete(response);
            } catch (e, stackTrace) {
              getRequestCompleter.completeError(e, stackTrace);
            }
          }),
        );

        final result = await minecraftAccountManager.loginWithMicrosoftAuthCode(
          onProgressUpdate: onProgressUpdate ?? (_, {authCodeLoginUrl}) {},
          successLoginPageContent:
              successLoginPageContent ?? successPageContent(),
        );

        final getRequestResponse = await getRequestCompleter.future.timeout(
          const Duration(seconds: 5),
        );

        return (result, getRequestResponse);
      }

      test('responds with HTML page and closes server on success', () async {
        final successLoginPageContent = successPageContent(
          title: 'You are logged in now!',
          pageDir: 'ltr',
          pageLangCode: 'en',
          pageTitle: 'Successful Login!',
          subtitle:
              'You can close this window now, the launcher is logging in...',
        );
        bool reachedExchangingAuthCodeProgress = false;
        final (
          AccountResult? result,
          String? response,
        ) = await simulateAuthCodeRedirect(
          authCode: fakeAuthCode,
          onProgressUpdate: (newProgress, {authCodeLoginUrl}) {
            if (newProgress == MicrosoftAuthProgress.exchangingAuthCode) {
              reachedExchangingAuthCodeProgress = true;
            }
          },
          successLoginPageContent: successLoginPageContent,
        );

        expect(reachedExchangingAuthCodeProgress, true);
        expect(minecraftAccountManager.isServerRunning, false);

        expect(response, buildAuthCodeSuccessPageHtml(successLoginPageContent));

        // Passes auth code correctly to Microsoft API
        verify(
          () => mockMicrosoftAuthApi.exchangeAuthCodeForTokens(fakeAuthCode),
        ).called(1);
      });

      test(
        'calls APIs correctly in order from Microsoft OAuth access token to Minecraft profile',
        () async {
          const microsoftOauthResponse = MicrosoftOauthTokenExchangeResponse(
            accessToken: 'accessToken',
            refreshToken: 'refreshToken2',
            expiresIn: 7000,
          );
          const requestXboxLiveTokenResponse = XboxLiveAuthTokenResponse(
            xboxToken: 'xboxToken',
            userHash: 'userHash',
          );
          const requestXstsTokenResponse = XboxLiveAuthTokenResponse(
            xboxToken: 'xboxToken2',
            userHash: 'userHash2',
          );
          const minecraftLoginResponse = MinecraftLoginResponse(
            username: 'dsadsadsa',
            accessToken: 'dsadsadsadsasaddsadkspaoasdsadsad321312321',
            expiresIn: -12,
          );

          const ownsMinecraftJava = true;

          when(
            () => mockMicrosoftAuthApi.exchangeAuthCodeForTokens(any()),
          ).thenAnswer((_) async => microsoftOauthResponse);
          when(
            () => mockMicrosoftAuthApi.requestXboxLiveToken(any()),
          ).thenAnswer((_) async => requestXboxLiveTokenResponse);
          when(
            () => mockMicrosoftAuthApi.requestXSTSToken(any()),
          ).thenAnswer((_) async => requestXstsTokenResponse);
          when(
            () => mockMinecraftApi.loginToMinecraftWithXbox(any()),
          ).thenAnswer((_) async => minecraftLoginResponse);
          when(
            () => mockMinecraftApi.checkMinecraftJavaOwnership(any()),
          ).thenAnswer((_) async => ownsMinecraftJava);

          final progressList = <MicrosoftAuthProgress>[];

          await simulateAuthCodeRedirect(
            authCode: fakeAuthCode,
            onProgressUpdate:
                (progress, {authCodeLoginUrl}) => progressList.add(progress),
          );

          expect(progressList, [
            MicrosoftAuthProgress.waitingForUserLogin,
            MicrosoftAuthProgress.exchangingAuthCode,
            MicrosoftAuthProgress.requestingXboxToken,
            MicrosoftAuthProgress.requestingXstsToken,
            MicrosoftAuthProgress.loggingIntoMinecraft,
            MicrosoftAuthProgress.fetchingProfile,
            MicrosoftAuthProgress.checkingMinecraftJavaOwnership,
          ]);
          verifyInOrder([
            () => mockMicrosoftAuthApi.userLoginUrlWithAuthCode(),
            () => mockMicrosoftAuthApi.exchangeAuthCodeForTokens(fakeAuthCode),
            () => mockMicrosoftAuthApi.requestXboxLiveToken(
              microsoftOauthResponse,
            ),
            () => mockMicrosoftAuthApi.requestXSTSToken(
              requestXboxLiveTokenResponse,
            ),
            () => mockMinecraftApi.loginToMinecraftWithXbox(
              requestXstsTokenResponse,
            ),
            () => mockMinecraftApi.fetchMinecraftProfile(
              minecraftLoginResponse.accessToken,
            ),
            () => mockMinecraftApi.checkMinecraftJavaOwnership(
              minecraftLoginResponse.accessToken,
            ),
          ]);
          verifyNoMoreInteractions(mockMicrosoftAuthApi);
          verifyNoMoreInteractions(mockMinecraftApi);
        },
      );

      test(
        'returns Minecraft account correctly based on the API responses',
        () async {
          const microsoftOauthResponse = MicrosoftOauthTokenExchangeResponse(
            accessToken: 'accessTokedadsdan',
            refreshToken: 'refreshToken2dasdsa',
            expiresIn: 3000,
          );

          const minecraftLoginResponse = MinecraftLoginResponse(
            username: 'dsadsadspmii90i90a',
            accessToken: 'dsadsadsadsas0opoplkopspaoasdsadsad321312321',
            expiresIn: -12,
          );

          const minecraftProfileResponse = MinecraftProfileResponse(
            id: 'dsadsadsadsa',
            name: 'Alex',
            skins: [
              MinecraftProfileSkin(
                id: 'id',
                state: 'INACTIVE',
                url: 'http://example',
                textureKey: 'dsadsads',
                variant: MinecraftSkinVariant.slim,
              ),
              MinecraftProfileSkin(
                id: 'id2',
                state: 'ACTIVE',
                url: 'http://example2',
                textureKey: 'dsadsadsads',
                variant: MinecraftSkinVariant.classic,
              ),
            ],
            capes: [
              MinecraftProfileCape(
                id: 'id',
                state: 'ACTIVE',
                url: 'http://example',
                alias: 'dasdsadas',
              ),
            ],
          );

          const ownsMinecraftJava = true;

          when(
            () => mockMicrosoftAuthApi.exchangeAuthCodeForTokens(any()),
          ).thenAnswer((_) async => microsoftOauthResponse);

          when(
            () => mockMinecraftApi.loginToMinecraftWithXbox(any()),
          ).thenAnswer((_) async => minecraftLoginResponse);
          when(
            () => mockMinecraftApi.fetchMinecraftProfile(any()),
          ).thenAnswer((_) async => minecraftProfileResponse);
          when(
            () => mockMinecraftApi.checkMinecraftJavaOwnership(any()),
          ).thenAnswer((_) async => ownsMinecraftJava);

          final (result, _) = await simulateAuthCodeRedirect();

          expect(
            result?.newAccount.toComparableJson(),
            MinecraftAccount.fromMinecraftProfileResponse(
              profileResponse: minecraftProfileResponse,
              oauthTokenResponse: microsoftOauthResponse,
              loginResponse: minecraftLoginResponse,
              ownsMinecraftJava: ownsMinecraftJava,
            ).toComparableJson(),
          );
        },
      );

      for (final ownsMinecraft in {true, false}) {
        test(
          'ownsMinecraft is $ownsMinecraft when the user ${ownsMinecraft ? 'have a valid copy of the game' : 'dont have a valid copy of the game'}',
          () async {
            when(
              () => mockMinecraftApi.checkMinecraftJavaOwnership(any()),
            ).thenAnswer((_) async => ownsMinecraft);

            final (result, _) = await simulateAuthCodeRedirect();
            expect(result?.newAccount.ownsMinecraftJava, ownsMinecraft);
          },
        );
      }
      _transformExceptionCommonTests(
        () => mockMinecraftApi,
        () => mockMicrosoftAuthApi,
        () => simulateAuthCodeRedirect(),
      );

      _commonLoginMicrosoftTests(
        mockAccountStorageProvider: () => mockAccountStorage,
        action: () async {
          final (result, _) = await simulateAuthCodeRedirect();
          return result;
        },
        mockMinecraftAccountCallback:
            (newAccount) =>
                mockMinecraftAccountAsLoginResult(newAccount, isAuthCode: true),
      );
    });
  });

  group('device code flow', () {
    test('deviceCodePollingTimer defaults to null', () {
      expect(minecraftAccountManager.deviceCodePollingTimer, null);
    });

    test('deviceCodePollingTimer the timer works correctly', () {
      fakeAsync((async) {
        bool callbackCalled = false;
        int timerCallbackInvocationCount = 0;

        const duration = Duration(seconds: 5);
        minecraftAccountManager.deviceCodePollingTimer = AsyncTimer.periodic(
          const Duration(seconds: 5),
          () {
            callbackCalled = true;
            timerCallbackInvocationCount++;
          },
        );

        expect(callbackCalled, false);
        expect(timerCallbackInvocationCount, 0);

        async.elapse(duration);

        expect(callbackCalled, true);
        expect(timerCallbackInvocationCount, 1);

        const additionalTicks = 500;
        for (int i = 0; i < additionalTicks; i++) {
          async.elapse(duration);
        }

        expect(timerCallbackInvocationCount, additionalTicks + 1);
      });
    });

    test(
      'isDeviceCodePollingTimerActive returns false when timer is not active',
      () {
        expect(minecraftAccountManager.isDeviceCodePollingTimerActive, false);
      },
    );

    AsyncTimer<MicrosoftDeviceCodeApproved?>
    dummyTimer() => AsyncTimer.periodic(
      // Dummy duration, this callback will not get invoked unless we call async.elapse().
      const Duration(seconds: 5),
      () => fail('Timer callback should not be called'),
    );

    test(
      'isDeviceCodePollingTimerActive returns true when timer is active',
      () {
        fakeAsync((async) {
          minecraftAccountManager.deviceCodePollingTimer = dummyTimer();

          expect(minecraftAccountManager.isDeviceCodePollingTimerActive, true);
          minecraftAccountManager.cancelDeviceCodePollingTimer();

          // Ensure cancellation
          expect(minecraftAccountManager.isDeviceCodePollingTimerActive, false);
          expect(minecraftAccountManager.deviceCodePollingTimer, null);
        });
      },
    );

    test('requestCancelDeviceCodePollingTimer defaults to false', () {
      expect(
        minecraftAccountManager.requestCancelDeviceCodePollingTimer,
        false,
      );
    });

    test('cancelDeviceCodePollingTimer cancels the timer correctly', () {
      fakeAsync((async) {
        // Assuming false to confirm the timer sets it to true.
        minecraftAccountManager.requestCancelDeviceCodePollingTimer = false;

        int timerCallbackInvocationCount = 0;
        const duration = Duration(seconds: 5);
        minecraftAccountManager.deviceCodePollingTimer = AsyncTimer.periodic(
          duration,
          () => timerCallbackInvocationCount++,
        );

        // Ensure the timer is currently active
        expect(minecraftAccountManager.isDeviceCodePollingTimerActive, true);
        expect(minecraftAccountManager.deviceCodePollingTimer, isNotNull);

        async.elapse(duration);
        expect(
          timerCallbackInvocationCount,
          1,
          reason: 'The timer is likely not working properly',
        );

        minecraftAccountManager.cancelDeviceCodePollingTimer();

        async.elapse(duration);
        expect(
          timerCallbackInvocationCount,
          1,
          reason:
              'The timer has been cancelled but the callback is still invoking, likely a bug.',
        );

        expect(
          minecraftAccountManager.requestCancelDeviceCodePollingTimer,
          true,
          reason:
              'Calling cancelDeviceCodePollingTimer should set requestCancelDeviceCodePollingTimer to false',
        );
        expect(minecraftAccountManager.deviceCodePollingTimer, isNull);
      });
    });

    Future<(AccountResult?, DeviceCodeTimerCloseReason)>
    requestLoginWithMicrosoftDeviceCode({
      OnAuthProgressUpdateCallback? onProgressUpdate,
      OnDeviceCodeAvailableCallback? onDeviceCodeAvailable,
    }) => minecraftAccountManager.requestLoginWithMicrosoftDeviceCode(
      onDeviceCodeAvailable: onDeviceCodeAvailable ?? (_) {},
      onProgressUpdate: onProgressUpdate ?? (_) {},
    );

    group('requestLoginWithMicrosoftDeviceCode', () {
      const int expiresInSeconds = 15 * 60; // 15 minutes
      const int interval = 5; // 5 seconds

      MicrosoftRequestDeviceCodeResponse requestCodeResponse({
        String userCode = '',
        int expiresIn = expiresInSeconds,
        int interval = interval,
      }) => MicrosoftRequestDeviceCodeResponse(
        userCode: userCode,
        deviceCode: '',
        expiresIn: expiresIn,
        interval: interval,
      );

      setUp(() {
        when(() => mockMicrosoftAuthApi.requestDeviceCode()).thenAnswer(
          (_) async => requestCodeResponse(expiresIn: -1, interval: -1),
        );
        when(
          () => mockMicrosoftAuthApi.checkDeviceCodeStatus(any()),
        ).thenAnswer(
          (_) async =>
              MicrosoftCheckDeviceCodeStatusResult.authorizationPending(),
        );
      });

      setUpAll(() {
        registerFallbackValue(
          const MicrosoftRequestDeviceCodeResponse(
            deviceCode: '',
            expiresIn: -1,
            interval: -1,
            userCode: '',
          ),
        );
      });
      test('sets requestCancelDeviceCodePollingTimer to false', () {
        minecraftAccountManager.requestCancelDeviceCodePollingTimer = true;
        requestLoginWithMicrosoftDeviceCode();
        expect(
          minecraftAccountManager.requestCancelDeviceCodePollingTimer,
          false,
        );
      });

      Future<(AccountResult?, DeviceCodeTimerCloseReason)> simulateExpiration({
        OnAuthProgressUpdateCallback? onProgressUpdate,
        OnDeviceCodeAvailableCallback? onDeviceCodeAvailable,
      }) {
        final completer =
            Completer<(AccountResult?, DeviceCodeTimerCloseReason)>();
        fakeAsync((async) {
          final future = requestLoginWithMicrosoftDeviceCode(
            onDeviceCodeAvailable: onDeviceCodeAvailable,
            onProgressUpdate: onProgressUpdate,
          );

          verify(() => mockMicrosoftAuthApi.requestDeviceCode()).called(1);

          // This will cause the timer to be cancelled the next time it triggers
          when(
            () => mockMicrosoftAuthApi.checkDeviceCodeStatus(any()),
          ).thenAnswer(
            (_) async => MicrosoftCheckDeviceCodeStatusResult.expired(),
          );

          future
              .then((result) {
                completer.complete(result);
              })
              .onError((e, stacktrace) {
                completer.completeError(e!, stacktrace);
              });

          // Trigger the timer callback
          async.elapse(const Duration(seconds: interval + 1));

          async.flushMicrotasks();
        });

        return completer.future.timeout(const Duration(seconds: 1));
      }

      Future<(AccountResult?, DeviceCodeTimerCloseReason)> simulateSuccess({
        OnAuthProgressUpdateCallback? onProgressUpdate,
        OnDeviceCodeAvailableCallback? onDeviceCodeAvailable,
        MicrosoftOauthTokenExchangeResponse? mockCheckCodeResponse,
        bool shouldMockCheckCodeResponse = true,
        MicrosoftRequestDeviceCodeResponse? mockRequestCodeResponse,
      }) {
        when(() => mockMicrosoftAuthApi.requestDeviceCode()).thenAnswer(
          (_) async =>
              mockRequestCodeResponse ??
              const MicrosoftRequestDeviceCodeResponse(
                deviceCode: '',
                userCode: '',
                interval: interval,
                expiresIn: 5000,
              ),
        );

        final completer =
            Completer<(AccountResult?, DeviceCodeTimerCloseReason)>();
        fakeAsync((async) {
          final future = requestLoginWithMicrosoftDeviceCode(
            onDeviceCodeAvailable: onDeviceCodeAvailable,
            onProgressUpdate: onProgressUpdate,
          );

          if (shouldMockCheckCodeResponse) {
            // This will cause the timer to be cancelled the next time it triggers
            when(
              () => mockMicrosoftAuthApi.checkDeviceCodeStatus(any()),
            ).thenAnswer(
              (_) async => MicrosoftCheckDeviceCodeStatusResult.approved(
                mockCheckCodeResponse ??
                    const MicrosoftOauthTokenExchangeResponse(
                      accessToken: '',
                      refreshToken: '',
                      expiresIn: -1,
                    ),
              ),
            );
          }

          future
              .then((result) {
                completer.complete(result);
              })
              .onError((e, stacktrace) {
                completer.completeError(e!, stacktrace);
              });

          // Trigger the timer callback
          async.elapse(const Duration(seconds: interval + 1));

          async.flushMicrotasks();
        });

        return completer.future.timeout(const Duration(seconds: 1));
      }

      test('requests device code and provides the user code', () async {
        const userDeviceCode = 'EXAMPLE-USER-CODE';
        final requestDeviceCodeResponse = requestCodeResponse(
          userCode: userDeviceCode,
          expiresIn: expiresInSeconds,
          interval: interval,
        );

        when(
          () => mockMicrosoftAuthApi.requestDeviceCode(),
        ).thenAnswer((_) async => requestDeviceCodeResponse);

        String? capturedUserDeviceCode;
        final progressList = <MicrosoftAuthProgress>[];
        await simulateExpiration(
          onDeviceCodeAvailable:
              (deviceCode) => capturedUserDeviceCode = deviceCode,
          onProgressUpdate: (newProgress) => progressList.add(newProgress),
        );

        verify(
          () => mockMicrosoftAuthApi.checkDeviceCodeStatus(
            requestDeviceCodeResponse,
          ),
        ).called(1);

        verifyNoMoreInteractions(mockMicrosoftAuthApi);
        verifyZeroInteractions(mockMinecraftApi);
        verifyZeroInteractions(mockAccountStorage);

        expect(capturedUserDeviceCode, userDeviceCode);
        expect(
          progressList.first,
          MicrosoftAuthProgress.waitingForUserLogin,
          reason:
              'onProgressUpdate should be called with ${MicrosoftAuthProgress.waitingForUserLogin.name} first. Progress list: $progressList',
        );
      });

      test('uses correct interval duration and advances timer accordingly', () {
        const fakeInterval = 50;
        when(() => mockMicrosoftAuthApi.requestDeviceCode()).thenAnswer(
          (_) async => requestCodeResponse(
            interval: fakeInterval,
            // Set a high expiration (in seconds) to simulate long-lived polling without triggering expiration.
            expiresIn: 5000000,
          ),
        );
        when(
          () => mockMicrosoftAuthApi.checkDeviceCodeStatus(any()),
        ).thenAnswer(
          (_) async =>
              MicrosoftCheckDeviceCodeStatusResult.authorizationPending(),
        );

        fakeAsync((async) {
          requestLoginWithMicrosoftDeviceCode();

          async.flushMicrotasks();

          expect(minecraftAccountManager.deviceCodePollingTimer?.timer.tick, 0);

          const duration = Duration(seconds: fakeInterval);

          async.elapse(duration);

          expect(minecraftAccountManager.deviceCodePollingTimer?.timer.tick, 1);

          async.elapse(duration);

          expect(minecraftAccountManager.deviceCodePollingTimer?.timer.tick, 2);

          final currentTicks =
              minecraftAccountManager.deviceCodePollingTimer!.timer.tick;

          const additionalTicks = 500;
          for (int i = 0; i < additionalTicks; i++) {
            async.elapse(duration);
          }

          expect(
            minecraftAccountManager.deviceCodePollingTimer!.timer.tick,
            currentTicks + additionalTicks,
          );

          minecraftAccountManager.cancelDeviceCodePollingTimer();
        });
      });

      test(
        'cancels timer on next run if cancellation was requested before timer initialization',
        () {
          // The timer can only be cancelled once it has been initialized. Before initialization,
          // the device code is requested, which is an asynchronous call. During this time,
          // users can cancel the operation, and the timer is null at this point.
          // The requestCancelDeviceCodePollingTimer flag is used to cancel the timer
          // the next time it is invoked, and it should be checked on each run.

          const requestDeviceCodeDuration = Duration(seconds: 10);

          fakeAsync((async) {
            when(() => mockMicrosoftAuthApi.requestDeviceCode()).thenAnswer((
              _,
            ) async {
              await Future<void>.delayed(requestDeviceCodeDuration);
              return requestCodeResponse();
            });

            // Login with device code was requested.
            final future = requestLoginWithMicrosoftDeviceCode();

            // The requestDeviceCode call is still not finished yet after this call.
            async.elapse(
              requestDeviceCodeDuration - const Duration(seconds: 2),
            );

            verify(() => mockMicrosoftAuthApi.requestDeviceCode()).called(1);

            // Users might want to login with auth code instead before requestDeviceCode finishes,
            // cancelling the device code polling.
            minecraftAccountManager.cancelDeviceCodePollingTimer();

            expect(
              minecraftAccountManager.requestCancelDeviceCodePollingTimer,
              true,
              reason:
                  'The requestCancelDeviceCodePollingTimer flag should be true when cancelDeviceCodePollingTimer is called',
            );

            async.elapse(requestDeviceCodeDuration);

            expect(
              minecraftAccountManager.deviceCodePollingTimer,
              null,
              reason:
                  'The timer should be cancelled and null when it was requested to be cancelled before it got initialized',
            );

            // Ensure the code execution stops (i.e., `return` is used) after the timer is closed.
            try {
              verifyNever(
                () => mockMicrosoftAuthApi.checkDeviceCodeStatus(any()),
              );
            } on TestFailure catch (e) {
              fail(
                'Expected no call to checkDeviceCodeStatus after the timer was canceled.\n'
                'This likely means execution continued past the cancel call — is `return;` used after cancelDeviceCodePollingTimer when requestCancelDeviceCodePollingTimer is true?\n'
                'Details: $e',
              );
            }

            bool callbackCompleted = false;
            future.then((result) {
              expect(result.$1, null);
              expect(
                result.$2,
                DeviceCodeTimerCloseReason.cancelledByUser,
                reason:
                    'The close reason should be ${DeviceCodeTimerCloseReason.cancelledByUser.name} because it was cancelled due to user request.',
              );
              callbackCompleted = true;
            });

            async.flushMicrotasks();
            expect(
              callbackCompleted,
              true,
              reason: 'The then callback was not completed',
            );
          });
        },
      );

      test(
        'cancels the timer and stops execution when the device code is expired while polling',
        () {
          const expiresIn = 5400;
          when(() => mockMicrosoftAuthApi.requestDeviceCode()).thenAnswer(
            (_) async =>
                requestCodeResponse(expiresIn: expiresIn, interval: interval),
          );

          when(
            () => mockMicrosoftAuthApi.checkDeviceCodeStatus(any()),
          ).thenAnswer(
            (_) async =>
                MicrosoftCheckDeviceCodeStatusResult.authorizationPending(),
          );

          fakeAsync((async) {
            final future = requestLoginWithMicrosoftDeviceCode();

            async.flushMicrotasks();
            expect(
              minecraftAccountManager.deviceCodePollingTimer,
              isNotNull,
              reason: 'The timer should be not null when it started',
            );

            const intervalDuration = Duration(seconds: interval);
            async.elapse(intervalDuration);

            expect(
              minecraftAccountManager.deviceCodePollingTimer,
              isNotNull,
              reason:
                  'The code is still not expired after first timer invocation',
            );

            // Number of check attempts in timer before it gets expired.
            // The check has run only once at this point.
            const totalCheckUntilExpired = expiresIn / interval;
            const checksUntilExpired = totalCheckUntilExpired - 1;

            const checksBeforeExpiration = checksUntilExpired - 1;
            for (int i = 0; i < checksBeforeExpiration; i++) {
              async.elapse(intervalDuration);
            }

            expect(
              minecraftAccountManager.deviceCodePollingTimer,
              isNotNull,
              reason:
                  'The code is still not expired before the last timer invocation',
            );

            async.elapse(intervalDuration);

            expect(
              minecraftAccountManager.deviceCodePollingTimer,
              isNull,
              reason:
                  'The timer should be cancelled after $totalCheckUntilExpired invocations where each invocation runs every ${intervalDuration.inSeconds}s since code expires in ${expiresIn}s',
            );

            bool callbackCompleted = false;
            future.then((result) {
              expect(result.$1, null);
              expect(
                result.$2,
                DeviceCodeTimerCloseReason.codeExpired,
                reason:
                    'The close reason should be ${DeviceCodeTimerCloseReason.codeExpired.name} as it was cancelled due to expiration',
              );
              callbackCompleted = true;
            });

            async.flushMicrotasks();
            expect(
              callbackCompleted,
              true,
              reason: 'The then callback was not completed',
            );
          });
        },
      );

      // It might be confusing, but currently both this test and
      // the one above it are testing the same thing in slightly different ways.
      // This test verifies whether the timer callback checks if the code is expired.
      // The test above this verifies whether the "Future.then" callback was used
      // to cancel the timer on expiration, which is outside of the timer callback.
      // Since the "Future.then" callback is always called in both cases, this test
      // will not fail if the callback doesn't check whether the code is expired.
      // Fixing this would require changes to production code, but it's not an issue.
      test(
        'cancels the timer and stops execution when the device code after awaiting for expiresIn',
        () {
          const expiresIn = 9200;
          when(() => mockMicrosoftAuthApi.requestDeviceCode()).thenAnswer(
            (_) async =>
                requestCodeResponse(expiresIn: expiresIn, interval: interval),
          );
          when(
            () => mockMicrosoftAuthApi.checkDeviceCodeStatus(any()),
          ).thenAnswer(
            (_) async =>
                MicrosoftCheckDeviceCodeStatusResult.authorizationPending(),
          );

          fakeAsync((async) {
            final future = requestLoginWithMicrosoftDeviceCode();

            async.flushMicrotasks();
            expect(minecraftAccountManager.deviceCodePollingTimer, isNotNull);
            async.elapse(const Duration(seconds: expiresIn));
            async.elapse(const Duration(seconds: interval));
            expect(minecraftAccountManager.deviceCodePollingTimer, null);

            bool callbackCompleted = false;
            future.then((result) {
              expect(result.$1, null);
              expect(
                result.$2,
                DeviceCodeTimerCloseReason.codeExpired,
                reason:
                    'The close reason should be ${DeviceCodeTimerCloseReason.codeExpired.name} as it was cancelled due to expiration',
              );
              callbackCompleted = true;
            });

            async.flushMicrotasks();
            expect(
              callbackCompleted,
              true,
              reason: 'The then callback was not completed',
            );
          });
        },
      );

      test('cancels timer as expired when API responds with expired', () async {
        when(
          () => mockMicrosoftAuthApi.checkDeviceCodeStatus(any()),
        ).thenAnswer(
          (_) async => MicrosoftCheckDeviceCodeStatusResult.expired(),
        );

        fakeAsync((async) {
          final future = requestLoginWithMicrosoftDeviceCode();

          async.flushMicrotasks();

          async.elapse(const Duration(seconds: interval));

          expect(minecraftAccountManager.deviceCodePollingTimer, null);

          bool callbackCompleted = false;
          future.then((result) {
            expect(result.$1, null);
            expect(result.$2, DeviceCodeTimerCloseReason.codeExpired);
            callbackCompleted = true;
          });

          async.flushMicrotasks();
          expect(
            callbackCompleted,
            true,
            reason: 'The then callback was not completed',
          );
        });
      });

      test('continues polling when API responds with pending', () {
        final requestDeviceCodeResponse = requestCodeResponse(
          expiresIn: 9000,
          interval: interval,
        );
        when(
          () => mockMicrosoftAuthApi.requestDeviceCode(),
        ).thenAnswer((_) async => requestDeviceCodeResponse);
        when(
          () => mockMicrosoftAuthApi.checkDeviceCodeStatus(any()),
        ).thenAnswer(
          (_) async =>
              MicrosoftCheckDeviceCodeStatusResult.authorizationPending(),
        );

        fakeAsync((async) {
          requestLoginWithMicrosoftDeviceCode();

          async.flushMicrotasks();

          verify(() => mockMicrosoftAuthApi.requestDeviceCode()).called(1);

          expect(minecraftAccountManager.deviceCodePollingTimer?.timer.tick, 0);

          const duration = Duration(seconds: interval);

          for (int i = 1; i <= 50; i++) {
            async.elapse(duration);
            expect(
              minecraftAccountManager.deviceCodePollingTimer?.timer.tick,
              i,
            );
            verify(
              () => mockMicrosoftAuthApi.checkDeviceCodeStatus(
                requestDeviceCodeResponse,
              ),
            ).called(1);
          }

          minecraftAccountManager.cancelDeviceCodePollingTimer();

          async.elapse(duration);
          expect(
            minecraftAccountManager.deviceCodePollingTimer?.timer.tick,
            null,
          );
          verifyNoMoreInteractions(mockMicrosoftAuthApi);
        });
      });

      test(
        'cancels the timer as ${DeviceCodeTimerCloseReason.approved} when API responds with success',
        () {
          when(() => mockMicrosoftAuthApi.requestDeviceCode()).thenAnswer(
            (_) async =>
                requestCodeResponse(expiresIn: 9000, interval: interval),
          );
          when(
            () => mockMicrosoftAuthApi.checkDeviceCodeStatus(any()),
          ).thenAnswer(
            (_) async => MicrosoftCheckDeviceCodeStatusResult.approved(
              const MicrosoftOauthTokenExchangeResponse(
                accessToken: '',
                refreshToken: '',
                expiresIn: -1,
              ),
            ),
          );

          fakeAsync((async) {
            final future = requestLoginWithMicrosoftDeviceCode();

            async.flushMicrotasks();
            async.elapse(const Duration(seconds: interval));

            bool callbackCompleted = false;
            future.then((result) {
              expect(result.$1, isNotNull);
              expect(
                result.$2,
                DeviceCodeTimerCloseReason.approved,
                reason:
                    'The close reason should be ${DeviceCodeTimerCloseReason.approved.name} because it was cancelled due to a successful login.',
              );
              callbackCompleted = true;
            });

            async.flushMicrotasks();
            expect(
              callbackCompleted,
              true,
              reason: 'The then callback was not completed',
            );
          });
        },
      );

      test(
        'returns close reason ${DeviceCodeTimerCloseReason.cancelledByUser} when user cancels the operation',
        () async {
          when(() => mockMicrosoftAuthApi.requestDeviceCode()).thenAnswer(
            (_) async => requestCodeResponse(
              expiresIn: expiresInSeconds,
              interval: interval,
            ),
          );

          fakeAsync((async) {
            final future = requestLoginWithMicrosoftDeviceCode();

            async.flushMicrotasks();

            async.elapse(const Duration(seconds: interval));

            minecraftAccountManager.cancelDeviceCodePollingTimer();

            bool callbackCompleted = true;
            future.then((result) {
              expect(result.$1, null);
              expect(
                result.$2,
                DeviceCodeTimerCloseReason.cancelledByUser,
                reason:
                    'The close reason should be ${DeviceCodeTimerCloseReason.cancelledByUser.name} because it was cancelled due to user request.',
              );
              callbackCompleted = true;
            });

            async.flushMicrotasks();
            expect(
              callbackCompleted,
              true,
              reason: 'The then callback was not completed',
            );
          });
        },
      );

      test(
        'returns close reason ${DeviceCodeTimerCloseReason.declined} when user cancels the operation',
        () async {
          when(() => mockMicrosoftAuthApi.requestDeviceCode()).thenAnswer(
            (_) async => requestCodeResponse(
              expiresIn: expiresInSeconds,
              interval: interval,
            ),
          );
          when(
            () => mockMicrosoftAuthApi.checkDeviceCodeStatus(any()),
          ).thenAnswer(
            (_) async => MicrosoftCheckDeviceCodeStatusResult.declined(),
          );
          fakeAsync((async) {
            final future = requestLoginWithMicrosoftDeviceCode();

            async.flushMicrotasks();

            async.elapse(const Duration(seconds: interval));

            minecraftAccountManager.cancelDeviceCodePollingTimer();

            bool callbackCompleted = true;
            future.then((result) {
              expect(result.$1, null);
              expect(
                result.$2,
                DeviceCodeTimerCloseReason.declined,
                reason:
                    'The close reason should be ${DeviceCodeTimerCloseReason.declined.name} because the user explicitly denied the authorization request, so the timer was cancelled as a result.',
              );
              callbackCompleted = true;
            });

            async.flushMicrotasks();
            expect(
              callbackCompleted,
              true,
              reason: 'The then callback was not completed',
            );
          });
        },
      );

      test(
        'calls APIs correctly in order from Microsoft OAuth access token to Minecraft profile',
        () async {
          const microsoftOauthResponse = MicrosoftOauthTokenExchangeResponse(
            accessToken: 'access token',
            refreshToken: 'refresh token',
            expiresIn: 4200,
          );
          const requestXboxLiveTokenResponse = XboxLiveAuthTokenResponse(
            xboxToken: 'xboxToken',
            userHash: 'userHash',
          );
          const requestXstsTokenResponse = XboxLiveAuthTokenResponse(
            xboxToken: 'xboxToken2',
            userHash: 'userHash2',
          );
          const minecraftLoginResponse = MinecraftLoginResponse(
            username: 'dsadsadsa',
            accessToken: 'dsadsadsadsasaddsadkspaoasdsadsad321312321',
            expiresIn: -12,
          );
          const requestDeviceCodeResponse = MicrosoftRequestDeviceCodeResponse(
            deviceCode: 'dsadsa',
            expiresIn: 5000,
            interval: 5,
            userCode: '',
          );

          const ownsMinecraftJava = true;

          when(
            () => mockMicrosoftAuthApi.requestXboxLiveToken(any()),
          ).thenAnswer((_) async => requestXboxLiveTokenResponse);
          when(
            () => mockMicrosoftAuthApi.requestXSTSToken(any()),
          ).thenAnswer((_) async => requestXstsTokenResponse);
          when(
            () => mockMinecraftApi.loginToMinecraftWithXbox(any()),
          ).thenAnswer((_) async => minecraftLoginResponse);
          when(
            () => mockMinecraftApi.checkMinecraftJavaOwnership(any()),
          ).thenAnswer((_) async => ownsMinecraftJava);

          final progressList = <MicrosoftAuthProgress>[];

          await simulateSuccess(
            mockRequestCodeResponse: requestDeviceCodeResponse,
            mockCheckCodeResponse: microsoftOauthResponse,
            onProgressUpdate:
                (progress, {authCodeLoginUrl}) => progressList.add(progress),
          );

          expect(progressList, [
            MicrosoftAuthProgress.waitingForUserLogin,
            MicrosoftAuthProgress.exchangingDeviceCode,
            MicrosoftAuthProgress.requestingXboxToken,
            MicrosoftAuthProgress.requestingXstsToken,
            MicrosoftAuthProgress.loggingIntoMinecraft,
            MicrosoftAuthProgress.fetchingProfile,
            MicrosoftAuthProgress.checkingMinecraftJavaOwnership,
          ]);
          verifyInOrder([
            () => mockMicrosoftAuthApi.requestDeviceCode(),
            () => mockMicrosoftAuthApi.checkDeviceCodeStatus(
              requestDeviceCodeResponse,
            ),
            () => mockMicrosoftAuthApi.requestXboxLiveToken(
              microsoftOauthResponse,
            ),
            () => mockMicrosoftAuthApi.requestXSTSToken(
              requestXboxLiveTokenResponse,
            ),
            () => mockMinecraftApi.loginToMinecraftWithXbox(
              requestXstsTokenResponse,
            ),
            () => mockMinecraftApi.fetchMinecraftProfile(
              minecraftLoginResponse.accessToken,
            ),
            () => mockMinecraftApi.checkMinecraftJavaOwnership(
              minecraftLoginResponse.accessToken,
            ),
          ]);
          verifyNoMoreInteractions(mockMicrosoftAuthApi);
          verifyNoMoreInteractions(mockMinecraftApi);
        },
      );

      test(
        'returns Minecraft account correctly based on the API responses',
        () async {
          const microsoftOauthResponse = MicrosoftOauthTokenExchangeResponse(
            accessToken: 'accessTokedadsdandsadsadas',
            refreshToken: 'refreshToken2dasdsadsadsadsadsa',
            expiresIn: 4000,
          );

          const minecraftLoginResponse = MinecraftLoginResponse(
            username: 'dsadsadspmiidsadsadsa90i90a',
            accessToken: 'dsadsadsadsas0opoplkopspaoasdsadsad321312321',
            expiresIn: 9600,
          );

          const minecraftProfileResponse = MinecraftProfileResponse(
            id: 'dsadsadsadsa',
            name: 'Alex',
            skins: [
              MinecraftProfileSkin(
                id: 'id',
                state: 'INACTIVE',
                url: 'http://edsadsaxample',
                textureKey: 'dsadsadsasdsads',
                variant: MinecraftSkinVariant.slim,
              ),
              MinecraftProfileSkin(
                id: 'id2',
                state: 'ACTIVE',
                url: 'http://exdsadsaample2',
                textureKey: 'dsadsadsads',
                variant: MinecraftSkinVariant.classic,
              ),
            ],
            capes: [
              MinecraftProfileCape(
                id: 'id',
                state: 'ACTIVE',
                url: 'http://example',
                alias: 'dasdsadas',
              ),
            ],
          );

          const ownsMinecraftJava = true;

          when(
            () => mockMinecraftApi.loginToMinecraftWithXbox(any()),
          ).thenAnswer((_) async => minecraftLoginResponse);
          when(
            () => mockMinecraftApi.fetchMinecraftProfile(any()),
          ).thenAnswer((_) async => minecraftProfileResponse);
          when(
            () => mockMinecraftApi.checkMinecraftJavaOwnership(any()),
          ).thenAnswer((_) async => ownsMinecraftJava);

          final (result, _) = await simulateSuccess(
            mockCheckCodeResponse: microsoftOauthResponse,
          );

          expect(
            result?.newAccount.toComparableJson(),
            MinecraftAccount.fromMinecraftProfileResponse(
              profileResponse: minecraftProfileResponse,
              oauthTokenResponse: microsoftOauthResponse,
              loginResponse: minecraftLoginResponse,
              ownsMinecraftJava: ownsMinecraftJava,
            ).toComparableJson(),
          );
        },
      );

      for (final ownsMinecraft in {true, false}) {
        test(
          'ownsMinecraft is $ownsMinecraft when the user ${ownsMinecraft ? 'have a valid copy of the game' : 'dont have a valid copy of the game'}',
          () async {
            when(
              () => mockMinecraftApi.checkMinecraftJavaOwnership(any()),
            ).thenAnswer((_) async => ownsMinecraft);

            final (result, _) = await simulateSuccess();
            expect(result?.newAccount.ownsMinecraftJava, ownsMinecraft);
          },
        );
      }

      _transformExceptionCommonTests(
        () => mockMinecraftApi,
        () => mockMicrosoftAuthApi,
        () => simulateSuccess(),
      );

      _commonLoginMicrosoftTests(
        mockAccountStorageProvider: () => mockAccountStorage,
        action: () async {
          final (result, _) = await simulateSuccess(
            shouldMockCheckCodeResponse: false,
          );
          return result;
        },
        mockMinecraftAccountCallback:
            (newAccount) => mockMinecraftAccountAsLoginResult(
              newAccount,
              isDeviceCode: true,
            ),
      );
    });
  });

  group('removeAccount', () {
    test('removes account from the list correctly', () {
      const id = 'minecraft-user-id';
      const initialAccounts = MinecraftAccounts(
        all: [
          MinecraftAccount(
            id: id,
            username: 'minecraft_username',
            accountType: AccountType.offline,
            microsoftAccountInfo: null,
            skins: [],
            ownsMinecraftJava: null,
          ),
          MinecraftAccount(
            id: 'minecraft-user-id-2',
            username: 'minecraft_username_2',
            accountType: AccountType.offline,
            microsoftAccountInfo: null,
            skins: [],
            ownsMinecraftJava: null,
          ),
        ],
        defaultAccountId: 'minecraft-user-id-2',
      );

      when(() => mockAccountStorage.loadAccounts()).thenReturn(initialAccounts);

      final newAccounts = minecraftAccountManager.removeAccount(id);
      expect(
        newAccounts.defaultAccountId,
        initialAccounts.defaultAccountId,
        reason:
            'Keeps defaultAccountId unchanged if the default account was not removed.',
      );
      expect(
        newAccounts.toComparableJson(),
        initialAccounts
            .copyWith(
              all: [...initialAccounts.all]
                ..removeWhere((account) => account.id == id),
            )
            .toComparableJson(),
      );

      verifyInOrder([
        () => mockAccountStorage.loadAccounts(),
        () => mockAccountStorage.saveAccounts(newAccounts),
      ]);
      verifyNoMoreInteractions(mockAccountStorage);

      verifyZeroInteractions(mockMinecraftApi);
      verifyZeroInteractions(mockMicrosoftAuthApi);
    });

    test('sets defaultAccountId to null when the only account is removed', () {
      const id = 'minecraft-user-id';
      const initialAccounts = MinecraftAccounts(
        all: [
          MinecraftAccount(
            id: id,
            username: 'minecraft_username',
            accountType: AccountType.offline,
            microsoftAccountInfo: null,
            skins: [],
            ownsMinecraftJava: null,
          ),
        ],
        defaultAccountId: id,
      );

      when(() => mockAccountStorage.loadAccounts()).thenReturn(initialAccounts);

      final newAccounts = minecraftAccountManager.removeAccount(id);
      expect(
        newAccounts.defaultAccountId,
        isNull,
        reason:
            'defaultAccountId should be null when the only account is removed',
      );
      expect(
        newAccounts.toComparableJson(),
        initialAccounts
            .copyWith(all: [], defaultAccountId: const Wrapped.value(null))
            .toComparableJson(),
      );
    });

    test(
      'sets defaultAccountId to next element when current default account is removed',
      () {
        const id = 'minecraft-account-id';
        const initialAccounts = MinecraftAccounts(
          all: [
            MinecraftAccount(
              id: id,
              username: 'minecraft_username',
              accountType: AccountType.offline,
              microsoftAccountInfo: null,
              skins: [],
              ownsMinecraftJava: null,
            ),
            MinecraftAccount(
              id: 'minecraft-next-account-id',
              username: 'minecraft_username_2',
              accountType: AccountType.offline,
              microsoftAccountInfo: null,
              skins: [],
              ownsMinecraftJava: null,
            ),
          ],
          defaultAccountId: id,
        );

        when(
          () => mockAccountStorage.loadAccounts(),
        ).thenReturn(initialAccounts);

        final newAccounts = minecraftAccountManager.removeAccount(id);
        expect(
          newAccounts.defaultAccountId,
          isNot(equals(id)),
          reason:
              'defaultAccountId should change when the default account is removed',
        );
        expect(
          newAccounts.defaultAccountId,
          initialAccounts.all.last.id,
          reason: 'defaultAccountId should change to the next account',
        );
      },
    );

    test(
      'sets defaultAccountId to the previous account when the default account is removed and it is the last account',
      () {
        const id = 'minecraft-account-id';
        const initialAccounts = MinecraftAccounts(
          all: [
            MinecraftAccount(
              id: 'minecraft-next-account-id',
              username: 'minecraft_username_2',
              accountType: AccountType.offline,
              microsoftAccountInfo: null,
              skins: [],
              ownsMinecraftJava: null,
            ),

            MinecraftAccount(
              id: id,
              username: 'minecraft_username',
              accountType: AccountType.offline,
              microsoftAccountInfo: null,
              skins: [],
              ownsMinecraftJava: null,
            ),
          ],
          defaultAccountId: id,
        );

        when(
          () => mockAccountStorage.loadAccounts(),
        ).thenReturn(initialAccounts);

        final newAccounts = minecraftAccountManager.removeAccount(id);
        expect(
          newAccounts.defaultAccountId,
          isNot(equals(id)),
          reason:
              'defaultAccountId should change when the default account is removed',
        );
        expect(
          newAccounts.defaultAccountId,
          initialAccounts.all.first.id,
          reason: 'defaultAccountId should be set to the previous account',
        );
      },
    );
  });

  group('loadAccounts', () {
    test('delegates to account storage', () {
      final accounts1 = MinecraftAccounts.empty();
      when(() => mockAccountStorage.loadAccounts()).thenReturn(accounts1);

      expect(
        minecraftAccountManager.loadAccounts().toComparableJson(),
        accounts1.toComparableJson(),
      );

      verify(() => mockAccountStorage.loadAccounts()).called(1);

      const accounts2 = MinecraftAccounts(
        all: [
          MinecraftAccount(
            id: 'id',
            username: 'username',
            accountType: AccountType.offline,
            microsoftAccountInfo: null,
            skins: [],
            ownsMinecraftJava: false,
          ),
        ],
        defaultAccountId: 'defaultAccountId',
      );

      when(() => mockAccountStorage.loadAccounts()).thenReturn(accounts2);

      expect(
        minecraftAccountManager.loadAccounts().toComparableJson(),
        accounts2.toComparableJson(),
      );

      verify(() => mockAccountStorage.loadAccounts()).called(1);
      verifyNoMoreInteractions(mockAccountStorage);

      verifyZeroInteractions(mockMicrosoftAuthApi);
      verifyZeroInteractions(mockMinecraftApi);
    });

    test('throws $UnknownAccountManagerException on $Exception', () {
      final exception = Exception('An example exception');
      when(() => mockAccountStorage.loadAccounts()).thenThrow(exception);

      expect(
        () => minecraftAccountManager.loadAccounts(),
        throwsA(
          isA<UnknownAccountManagerException>().having(
            (e) => e.message,
            'message',
            equals(exception.toString()),
          ),
        ),
      );

      verify(() => mockAccountStorage.loadAccounts()).called(1);
      verifyNoMoreInteractions(mockAccountStorage);
    });
  });

  test('updateDefaultAccount updates defaultAccountId correctly', () {
    const currentDefaultAccountId = 'id2';
    const newDefaultAccountId = 'id1';

    const initialAccounts = MinecraftAccounts(
      all: [
        MinecraftAccount(
          id: newDefaultAccountId,
          username: 'username',
          accountType: AccountType.offline,
          microsoftAccountInfo: null,
          skins: [],
          ownsMinecraftJava: false,
        ),
        MinecraftAccount(
          id: currentDefaultAccountId,
          username: 'username',
          accountType: AccountType.offline,
          microsoftAccountInfo: null,
          skins: [],
          ownsMinecraftJava: false,
        ),
      ],
      defaultAccountId: currentDefaultAccountId,
    );
    when(() => mockAccountStorage.loadAccounts()).thenReturn(initialAccounts);

    final accounts = minecraftAccountManager.updateDefaultAccount(
      newDefaultAccountId: newDefaultAccountId,
    );

    expect(accounts.defaultAccountId, newDefaultAccountId);
    expect(
      accounts.toComparableJson(),
      initialAccounts
          .copyWith(defaultAccountId: const Wrapped.value(newDefaultAccountId))
          .toComparableJson(),
    );

    verify(() => mockAccountStorage.loadAccounts()).called(1);
    verify(() => mockAccountStorage.saveAccounts(accounts)).called(1);
    verifyNoMoreInteractions(mockAccountStorage);

    verifyZeroInteractions(mockMicrosoftAuthApi);
    verifyZeroInteractions(mockMinecraftApi);
  });

  group('createOfflineAccount', () {
    test('creates the account details correctly', () {
      const username = 'example_username';
      final result = minecraftAccountManager.createOfflineAccount(
        username: username,
      );
      final newAccount = result.newAccount;
      expect(newAccount.accountType, AccountType.offline);
      expect(newAccount.isMicrosoft, false);
      expect(newAccount.username, username);
      expect(newAccount.ownsMinecraftJava, null);
      expect(newAccount.skins, <MinecraftSkin>[]);
      expect(newAccount.ownsMinecraftJava, null);

      final uuidV4Regex = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
      );
      expect(newAccount.id, matches(uuidV4Regex));

      expect(result.hasUpdatedExistingAccount, false);
    });

    test('saves and adds the account to the list when there are no accounts', () {
      when(
        () => mockAccountStorage.loadAccounts(),
      ).thenReturn(MinecraftAccounts.empty());

      final result = minecraftAccountManager.createOfflineAccount(username: '');
      final newAccount = result.newAccount;

      expect(
        result.updatedAccounts.defaultAccountId,
        newAccount.id,
        reason:
            'The defaultAccountId should be set to the newly created account when there are no accounts.',
      );
      expect(
        result.updatedAccounts.toComparableJson(),
        MinecraftAccounts(
          all: [newAccount],
          defaultAccountId: newAccount.id,
        ).toComparableJson(),
      );
      expect(result.updatedAccounts.all.length, 1);

      verifyInOrder([
        () => mockAccountStorage.loadAccounts(),
        () => mockAccountStorage.saveAccounts(result.updatedAccounts),
      ]);
      verifyNoMoreInteractions(mockAccountStorage);

      verifyZeroInteractions(mockMicrosoftAuthApi);
      verifyZeroInteractions(mockMinecraftApi);
    });

    test('saves and adds the account to the list when there are accounts', () {
      const currentDefaultAccountId = 'player-id2';
      final existingAccounts = MinecraftAccounts(
        all: [
          const MinecraftAccount(
            id: currentDefaultAccountId,
            username: 'player_username2',
            accountType: AccountType.offline,
            microsoftAccountInfo: null,
            skins: [],
            ownsMinecraftJava: true,
          ),
          MinecraftAccount(
            id: 'player-id',
            username: 'player_username',
            accountType: AccountType.microsoft,
            microsoftAccountInfo: MicrosoftAccountInfo(
              microsoftOAuthAccessToken: ExpirableToken(
                value: 'microsoft-access-token',
                expiresAt: DateTime(2020, 1, 20, 15, 40),
              ),
              microsoftOAuthRefreshToken: 'microsoft-refresh-token',
              minecraftAccessToken: ExpirableToken(
                value: 'minecraft-access-token',
                expiresAt: DateTime(2015, 1, 20, 15, 40),
              ),
            ),
            skins: const [
              MinecraftSkin(
                id: 'id',
                state: 'ACTIVE',
                url: 'http://dasdsas',
                textureKey: 'dasdsadsadsa',
                variant: MinecraftSkinVariant.classic,
              ),
              MinecraftSkin(
                id: 'iadsadasd',
                state: 'INACTIVE',
                url: 'http://dasddsadsasas',
                textureKey: 'dsad2sadsadsa',
                variant: MinecraftSkinVariant.slim,
              ),
            ],
            ownsMinecraftJava: true,
          ),
        ],
        defaultAccountId: currentDefaultAccountId,
      );
      when(
        () => mockAccountStorage.loadAccounts(),
      ).thenReturn(existingAccounts);

      final result = minecraftAccountManager.createOfflineAccount(username: '');
      final newAccount = result.newAccount;

      expect(
        result.updatedAccounts.defaultAccountId,
        currentDefaultAccountId,
        reason:
            'Should keep defaultAccountId unchanged when there is already an existing default account.',
      );
      expect(
        result.updatedAccounts.toComparableJson(),
        MinecraftAccounts(
          all: [newAccount, ...existingAccounts.all],
          defaultAccountId: currentDefaultAccountId,
        ).toComparableJson(),
      );
      expect(
        result.updatedAccounts.all.length,
        existingAccounts.all.length + 1,
      );

      verifyInOrder([
        () => mockAccountStorage.loadAccounts(),
        () => mockAccountStorage.saveAccounts(result.updatedAccounts),
      ]);
      verifyNoMoreInteractions(mockAccountStorage);

      verifyZeroInteractions(mockMicrosoftAuthApi);
      verifyZeroInteractions(mockMinecraftApi);
    });

    test('creates unique id', () {
      final id1 =
          minecraftAccountManager
              .createOfflineAccount(username: '')
              .newAccount
              .id;
      final id2 =
          minecraftAccountManager
              .createOfflineAccount(username: '')
              .newAccount
              .id;
      final id3 =
          minecraftAccountManager
              .createOfflineAccount(username: '')
              .newAccount
              .id;
      expect(id1, isNot(equals(id2)));
      expect(id2, isNot(equals(id3)));
      expect(id3, isNot(equals(id1)));
    });
  });

  test('updateOfflineAccount updates the account correctly', () {
    const accountId = 'player-id2';
    const originalAccount = MinecraftAccount(
      id: accountId,
      username: 'player_username2',
      accountType: AccountType.offline,
      microsoftAccountInfo: null,
      skins: [],
      ownsMinecraftJava: true,
    );
    final initialAccounts = MinecraftAccounts(
      all: [
        originalAccount,
        MinecraftAccount(
          id: 'player-id',
          username: 'player_username',
          accountType: AccountType.microsoft,
          microsoftAccountInfo: MicrosoftAccountInfo(
            microsoftOAuthAccessToken: ExpirableToken(
              value: 'microsoft-access-token',
              expiresAt: DateTime(2009, 1, 20, 15, 40),
            ),
            microsoftOAuthRefreshToken: 'microsoft-refresh-token',
            minecraftAccessToken: ExpirableToken(
              value: 'minecraft-access-token',
              expiresAt: DateTime(1995, 1, 20, 15, 40),
            ),
          ),
          skins: const [
            MinecraftSkin(
              id: 'id',
              state: 'ACTIVE',
              url: 'http://dasdsas',
              textureKey: 'dasdsadsadsa',
              variant: MinecraftSkinVariant.classic,
            ),
            MinecraftSkin(
              id: 'iadsadasd',
              state: 'INACTIVE',
              url: 'http://dasddsadsasas',
              textureKey: 'dsad2sadsadsa',
              variant: MinecraftSkinVariant.slim,
            ),
          ],
          ownsMinecraftJava: true,
        ),
      ],
      defaultAccountId: accountId,
    );

    when(() => mockAccountStorage.loadAccounts()).thenReturn(initialAccounts);

    const newUsername = 'new_player_username4';
    final result = minecraftAccountManager.updateOfflineAccount(
      accountId: accountId,
      username: newUsername,
    );
    final updatedAccount = result.newAccount;

    expect(updatedAccount.id, originalAccount.id);
    expect(updatedAccount.accountType, AccountType.offline);
    expect(updatedAccount.isMicrosoft, false);
    expect(updatedAccount.microsoftAccountInfo, null);
    expect(updatedAccount.username, newUsername);
    expect(updatedAccount.skins, isEmpty);
    expect(
      updatedAccount.toComparableJson(),
      originalAccount.copyWith(username: newUsername).toComparableJson(),
    );
    expect(
      result.updatedAccounts.defaultAccountId,
      initialAccounts.defaultAccountId,
    );

    final originalAccountIndex = initialAccounts.all.indexWhere(
      (account) => account.id == originalAccount.id,
    );
    expect(
      result.updatedAccounts.toComparableJson(),
      initialAccounts
          .copyWith(
            all:
                (initialAccounts..all[originalAccountIndex] = updatedAccount)
                    .all,
          )
          .toComparableJson(),
    );
    expect(result.hasUpdatedExistingAccount, true);

    verifyInOrder([
      () => mockAccountStorage.loadAccounts(),
      () => mockAccountStorage.saveAccounts(result.updatedAccounts),
    ]);
    verifyNoMoreInteractions(mockAccountStorage);

    verifyZeroInteractions(mockMinecraftApi);
    verifyZeroInteractions(mockMicrosoftAuthApi);
  });

  group('refreshMicrosoftAccount', () {
    setUp(() {
      when(
        () => mockMicrosoftAuthApi.getNewTokensFromRefreshToken(any()),
      ).thenAnswer(
        (_) async => const MicrosoftOauthTokenExchangeResponse(
          accessToken: '',
          expiresIn: -1,
          refreshToken: '',
        ),
      );
      when(
        () => mockImageCacheService.evictFromCache(any()),
      ).thenAnswer((_) async => true);
    });

    Future<(AccountResult refreshResult, MinecraftAccount existingAccount)>
    refreshAccount({
      String? id,
      List<MinecraftSkin>? skinsBeforeRefresh,

      /// Always null when [isMicrosoftAccountInfoNull] is true.
      String? microsoftOAuthRefreshTokenBeforeRefresh,
      bool isMicrosoftAccountInfoNull = false,
      OnAuthProgressUpdateCallback? onProgressUpdate,
    }) async {
      final existingAccount = MinecraftAccount(
        id: id ?? 'minecraft_id',
        username: 'username',
        accountType: AccountType.microsoft,
        microsoftAccountInfo:
            isMicrosoftAccountInfoNull
                ? null
                : MicrosoftAccountInfo(
                  microsoftOAuthAccessToken: ExpirableToken(
                    value: 'microsoft-access-token',
                    expiresAt: DateTime(2018, 1, 20, 15, 40),
                  ),
                  microsoftOAuthRefreshToken:
                      microsoftOAuthRefreshTokenBeforeRefresh ??
                      'microsoft-refresh-token',
                  minecraftAccessToken: ExpirableToken(
                    value: 'minecraft-access-token',
                    expiresAt: DateTime(2017, 1, 20, 15, 40),
                  ),
                ),
        skins: skinsBeforeRefresh ?? const [],
        ownsMinecraftJava: false,
      );
      final refreshResult = await minecraftAccountManager
          .refreshMicrosoftAccount(
            existingAccount,
            onProgressUpdate: onProgressUpdate ?? (_) {},
          );
      return (refreshResult, existingAccount);
    }

    test('throws $Exception when Microsoft refresh token is null', () async {
      await expectLater(
        refreshAccount(isMicrosoftAccountInfoNull: true),
        throwsException,
      );
    });

    test('updates progress and passes refresh token correctly', () async {
      final progressList = <MicrosoftAuthProgress>[];
      const refreshToken = 'Example OAuth Refresh token';
      await refreshAccount(
        onProgressUpdate: (newProgress) => progressList.add(newProgress),
        microsoftOAuthRefreshTokenBeforeRefresh: refreshToken,
      );

      expect(
        progressList.first,
        MicrosoftAuthProgress.refreshingMicrosoftTokens,
        reason:
            'onProgressUpdate should be called with ${MicrosoftAuthProgress.refreshingMicrosoftTokens.name} first. Progress list: $progressList',
      );
      final verificationResult = verify(
        () => mockMicrosoftAuthApi.getNewTokensFromRefreshToken(captureAny()),
      );
      verificationResult.called(1);
      final capturedRefreshToken = verificationResult.captured.first as String?;

      expect(capturedRefreshToken, refreshToken);
    });

    test('deletes current cached skin images', () async {
      const exampleUserId = 'Example Minecraft ID';
      final (result, existingAccount) = await refreshAccount(id: exampleUserId);
      verify(
        () => mockImageCacheService.evictFromCache(
          existingAccount.fullSkinImageUrl,
        ),
      ).called(1);
      verify(
        () => mockImageCacheService.evictFromCache(
          existingAccount.headSkinImageUrl,
        ),
      ).called(1);
    });

    test(
      'calls APIs correctly in order from Microsoft OAuth refresh token to Minecraft profile',
      () async {
        const microsoftOauthResponse = MicrosoftOauthTokenExchangeResponse(
          accessToken: 'accessToken22',
          refreshToken: 'rexsxfreshToken2',
          expiresIn: 3200,
        );
        const requestXboxLiveTokenResponse = XboxLiveAuthTokenResponse(
          xboxToken: 'xboxToken',
          userHash: 'userHash',
        );
        const requestXstsTokenResponse = XboxLiveAuthTokenResponse(
          xboxToken: 'xboxToken2',
          userHash: 'userHash2',
        );
        const minecraftLoginResponse = MinecraftLoginResponse(
          username: 'dsadsadsa',
          accessToken: 'dsadsadsadsasaddsadkspaoasdsadsad321312321',
          expiresIn: -12,
        );

        const ownsMinecraftJava = true;

        when(
          () => mockMicrosoftAuthApi.getNewTokensFromRefreshToken(any()),
        ).thenAnswer((_) async => microsoftOauthResponse);
        when(
          () => mockMicrosoftAuthApi.requestXboxLiveToken(any()),
        ).thenAnswer((_) async => requestXboxLiveTokenResponse);
        when(
          () => mockMicrosoftAuthApi.requestXSTSToken(any()),
        ).thenAnswer((_) async => requestXstsTokenResponse);
        when(
          () => mockMinecraftApi.loginToMinecraftWithXbox(any()),
        ).thenAnswer((_) async => minecraftLoginResponse);
        when(
          () => mockMinecraftApi.checkMinecraftJavaOwnership(any()),
        ).thenAnswer((_) async => ownsMinecraftJava);

        final progressList = <MicrosoftAuthProgress>[];

        const inputRefreshToken = 'dsadsdipasjkdsaopdisa';
        await refreshAccount(
          onProgressUpdate:
              (progress, {authCodeLoginUrl}) => progressList.add(progress),
          microsoftOAuthRefreshTokenBeforeRefresh: inputRefreshToken,
        );

        expect(progressList, [
          MicrosoftAuthProgress.refreshingMicrosoftTokens,
          MicrosoftAuthProgress.requestingXboxToken,
          MicrosoftAuthProgress.requestingXstsToken,
          MicrosoftAuthProgress.loggingIntoMinecraft,
          MicrosoftAuthProgress.fetchingProfile,
          MicrosoftAuthProgress.checkingMinecraftJavaOwnership,
        ]);
        verifyInOrder([
          () => mockMicrosoftAuthApi.getNewTokensFromRefreshToken(
            inputRefreshToken,
          ),
          () =>
              mockMicrosoftAuthApi.requestXboxLiveToken(microsoftOauthResponse),
          () => mockMicrosoftAuthApi.requestXSTSToken(
            requestXboxLiveTokenResponse,
          ),
          () => mockMinecraftApi.loginToMinecraftWithXbox(
            requestXstsTokenResponse,
          ),
          () => mockMinecraftApi.fetchMinecraftProfile(
            minecraftLoginResponse.accessToken,
          ),
          () => mockMinecraftApi.checkMinecraftJavaOwnership(
            minecraftLoginResponse.accessToken,
          ),
        ]);
        verifyNoMoreInteractions(mockMicrosoftAuthApi);
        verifyNoMoreInteractions(mockMinecraftApi);
      },
    );

    test(
      'returns Minecraft account correctly based on the API responses',
      () async {
        const microsoftOauthResponse = MicrosoftOauthTokenExchangeResponse(
          accessToken: 'accessTokedadsdan',
          refreshToken: 'refreshToken2dasdsa',
          expiresIn: 3000,
        );

        const minecraftLoginResponse = MinecraftLoginResponse(
          username: 'dsadsadspmii90i90a',
          accessToken: 'dsadsadsadsas0opoplkopspaoasdsadsad321312321',
          expiresIn: -12,
        );

        const minecraftProfileResponse = MinecraftProfileResponse(
          id: 'dsadsadsadsa',
          name: 'Alex',
          skins: [
            MinecraftProfileSkin(
              id: 'id',
              state: 'INACTIVE',
              url: 'http://example',
              textureKey: 'dsadsads',
              variant: MinecraftSkinVariant.slim,
            ),
            MinecraftProfileSkin(
              id: 'id2',
              state: 'ACTIVE',
              url: 'http://example2',
              textureKey: 'dsadsadsads',
              variant: MinecraftSkinVariant.classic,
            ),
          ],
          capes: [
            MinecraftProfileCape(
              id: 'id',
              state: 'ACTIVE',
              url: 'http://example',
              alias: 'dasdsadas',
            ),
          ],
        );

        const ownsMinecraftJava = true;

        when(
          () => mockMicrosoftAuthApi.getNewTokensFromRefreshToken(any()),
        ).thenAnswer((_) async => microsoftOauthResponse);

        when(
          () => mockMinecraftApi.loginToMinecraftWithXbox(any()),
        ).thenAnswer((_) async => minecraftLoginResponse);
        when(
          () => mockMinecraftApi.fetchMinecraftProfile(any()),
        ).thenAnswer((_) async => minecraftProfileResponse);
        when(
          () => mockMinecraftApi.checkMinecraftJavaOwnership(any()),
        ).thenAnswer((_) async => ownsMinecraftJava);

        final (result, _) = await refreshAccount();

        expect(
          result.newAccount.toComparableJson(),
          MinecraftAccount.fromMinecraftProfileResponse(
            profileResponse: minecraftProfileResponse,
            oauthTokenResponse: microsoftOauthResponse,
            loginResponse: minecraftLoginResponse,
            ownsMinecraftJava: ownsMinecraftJava,
          ).toComparableJson(),
        );
      },
    );

    for (final ownsMinecraft in {true, false}) {
      test(
        'ownsMinecraft is $ownsMinecraft when the user ${ownsMinecraft ? 'have a valid copy of the game' : 'dont have a valid copy of the game'}',
        () async {
          when(
            () => mockMinecraftApi.checkMinecraftJavaOwnership(any()),
          ).thenAnswer((_) async => ownsMinecraft);

          final (result, _) = await refreshAccount();
          expect(result.newAccount.ownsMinecraftJava, ownsMinecraft);
        },
      );
    }

    _transformExceptionCommonTests(
      () => mockMinecraftApi,
      () => mockMicrosoftAuthApi,
      () => refreshAccount(),
    );

    test(
      'saves and returns the refreshed account correctly without modifying other accounts',
      () async {
        const refreshAccountId = 'player-id';
        final accountBeforeRefresh = MinecraftAccount(
          id: refreshAccountId,
          username: 'player_name_before_refresh',
          accountType: AccountType.microsoft,
          microsoftAccountInfo: MicrosoftAccountInfo(
            microsoftOAuthAccessToken: ExpirableToken(
              value: 'microsoft-access-token',
              expiresAt: DateTime(2029, 5, 20, 15),
            ),
            microsoftOAuthRefreshToken:
                'microsoft-refresh-token-before-refresh',
            minecraftAccessToken: ExpirableToken(
              value: 'minecraft-access-token',
              expiresAt: DateTime(2014, 3, 15, 28),
            ),
          ),
          skins: const [
            MinecraftSkin(
              id: 'id',
              state: 'ACTIVE',
              url: 'http://dasdsas',
              textureKey: 'dasdsadsadsa',
              variant: MinecraftSkinVariant.classic,
            ),
            MinecraftSkin(
              id: 'iadsadasd',
              state: 'INACTIVE',
              url: 'http://dasddsadsasas',
              textureKey: 'dsad2sadsadsa',
              variant: MinecraftSkinVariant.slim,
            ),
          ],
          ownsMinecraftJava: true,
        );
        const currentDefaultAccountId = 'current-default-account-id';
        final existingAccounts = MinecraftAccounts(
          all: [
            const MinecraftAccount(
              id: currentDefaultAccountId,
              username: 'player_username2',
              accountType: AccountType.offline,
              microsoftAccountInfo: null,
              skins: [],
              ownsMinecraftJava: false,
            ),
            const MinecraftAccount(
              id: 'account-id3',
              username: 'player_username3',
              accountType: AccountType.offline,
              microsoftAccountInfo: null,
              skins: [],
              ownsMinecraftJava: false,
            ),
            accountBeforeRefresh,
          ],
          defaultAccountId: currentDefaultAccountId,
        );

        when(
          () => mockAccountStorage.loadAccounts(),
        ).thenReturn(existingAccounts);

        final expectedRefreshedAccount = accountBeforeRefresh.copyWith(
          username: 'new_player_username_after_refresh',
          skins: [
            const MinecraftSkin(
              id: 'refreshed-skin',
              state: 'ACTIVE',
              url: 'http://dasdsasdsadsa',
              textureKey: 'dasdsadsadsadsadsa',
              variant: MinecraftSkinVariant.slim,
            ),
          ],
          microsoftAccountInfo: MicrosoftAccountInfo(
            microsoftOAuthAccessToken: ExpirableToken(
              value: 'microsoft-access-token-after-refresh',
              expiresAt: DateTime(2029, 3, 21, 12, 43),
            ),
            microsoftOAuthRefreshToken: 'microsoft-refresh-token-after-refresh',
            minecraftAccessToken: ExpirableToken(
              value: 'minecraft-access-token-after-refresh',
              expiresAt: DateTime(2027, 2, 27, 12, 30),
            ),
          ),
        );
        mockMinecraftAccountAsLoginResult(
          expectedRefreshedAccount,
          isRefreshAccount: true,
        );

        final ((result), _) = await refreshAccount(id: refreshAccountId);
        final updatedAccounts = result.updatedAccounts;
        final refreshedAccount = result.newAccount;

        expect(
          updatedAccounts.defaultAccountId,
          existingAccounts.defaultAccountId,
          reason:
              'The defaultAccountId should remain untouched when refreshing an account.',
        );
        expect(
          refreshedAccount.accountType,
          AccountType.microsoft,
          reason:
              'The accountType should remain ${AccountType.microsoft.name} when refreshing a Microsoft account.',
        );
        expect(
          refreshedAccount.id,
          accountBeforeRefresh.id,
          reason:
              'The account id should remain the same when refreshing a Microsoft account.',
        );
        expect(
          refreshedAccount.toComparableJson(),
          expectedRefreshedAccount.toComparableJson(),
        );
        expect(
          result.updatedAccounts.all.length,
          existingAccounts.all.length,
          reason: 'Refreshing an account should not add or remove accounts.',
        );

        expect(
          result.updatedAccounts.toComparableJson(),
          existingAccounts
              .copyWith(
                all: result.updatedAccounts.all.updateById(
                  refreshAccountId,
                  expectedRefreshedAccount,
                ),
              )
              .toComparableJson(),
        );

        verify(() => mockAccountStorage.loadAccounts()).called(1);
        verify(
          () => mockAccountStorage.saveAccounts(result.updatedAccounts),
        ).called(1);
        verifyNoMoreInteractions(mockAccountStorage);
      },
    );
  });
}

// The APIs provides expiresIn, since the expiresAt depends on
// on the expiresIn, there is very short delay when
// fromMinecraftProfileResponse called in production code and in the test
// code, creating a difference, workaround this by trimming the seconds.
MinecraftAccount _trimSecondsFromAccountExpireAtDateTimes(
  MinecraftAccount account,
) {
  return account.copyWith(
    microsoftAccountInfo: account.microsoftAccountInfo?.copyWith(
      microsoftOAuthAccessToken: account
          .microsoftAccountInfo
          ?.microsoftOAuthAccessToken
          .copyWith(
            expiresAt:
                account
                    .microsoftAccountInfo
                    ?.microsoftOAuthAccessToken
                    .expiresAt
                    .trimSeconds(),
          ),
      minecraftAccessToken: account.microsoftAccountInfo?.minecraftAccessToken
          .copyWith(
            expiresAt:
                account.microsoftAccountInfo?.minecraftAccessToken.expiresAt
                    .trimSeconds(),
          ),
    ),
  );
}

extension _MinecraftAccountExt on MinecraftAccount {
  JsonObject toComparableJson() =>
      _trimSecondsFromAccountExpireAtDateTimes(this).toJson();
}

extension _MinecraftAccountsExt on MinecraftAccounts {
  MinecraftAccounts _trimSecondsFromAccountsExpireAtDateTimes(
    MinecraftAccounts accounts,
  ) => accounts.copyWith(
    all:
        accounts.all
            .map((account) => _trimSecondsFromAccountExpireAtDateTimes(account))
            .toList(),
  );

  JsonObject toComparableJson() =>
      _trimSecondsFromAccountsExpireAtDateTimes(this).toJson();
}

// Tests for all functions that uses _transformExceptions
void _transformExceptionCommonTests(
  MockMinecraftApi Function() mockMinecraftApi,
  MockMicrosoftAuthApi Function() mockMicrosoftAuthApi,
  Future<void> Function() action,
) {
  test(
    'throws $MinecraftApiAccountManagerException on $MinecraftApiException',
    () async {
      final minecraftApiException = MinecraftApiException.tooManyRequests();
      when(
        () => mockMinecraftApi().fetchMinecraftProfile(any()),
      ).thenAnswer((_) async => throw minecraftApiException);
      await expectLater(
        action(),
        throwsA(
          isA<MinecraftApiAccountManagerException>().having(
            (e) => e.minecraftApiException,
            'minecraftApiException',
            equals(minecraftApiException),
          ),
        ),
      );
    },
  );

  test(
    'throws $MicrosoftApiAccountManagerException on $MicrosoftAuthException',
    () async {
      final microsoftAuthException = MicrosoftAuthException.authCodeExpired();
      when(
        () => mockMicrosoftAuthApi().requestXboxLiveToken(any()),
      ).thenAnswer((_) async => throw microsoftAuthException);
      await expectLater(
        action(),
        throwsA(
          isA<MicrosoftApiAccountManagerException>().having(
            (e) => e.authApiException,
            'microsoftAuthException',
            equals(microsoftAuthException),
          ),
        ),
      );
    },
  );

  test('throws $UnknownAccountManagerException on $Exception', () async {
    final exception = Exception('Hello, World!');
    when(
      () => mockMicrosoftAuthApi().requestXboxLiveToken(any()),
    ).thenAnswer((_) async => throw exception);
    await expectLater(
      action(),
      throwsA(
        isA<UnknownAccountManagerException>().having(
          (e) => e.message,
          'message',
          equals(exception.toString()),
        ),
      ),
    );
  });

  test('rethrows $AccountManagerException when caught', () async {
    final exception = AccountManagerException.unknown(
      'Unknown',
      StackTrace.current,
    );

    when(
      () => mockMicrosoftAuthApi().requestXboxLiveToken(any()),
    ).thenAnswer((_) async => throw exception);

    await expectLater(
      action(),
      throwsA(
        isA<UnknownAccountManagerException>().having(
          (e) => e.message,
          'message',
          equals(exception.toString()),
        ),
      ),
    );
  });
}

void _commonLoginMicrosoftTests({
  required MockAccountStorage Function() mockAccountStorageProvider,
  required Future<AccountResult?> Function() action,
  required void Function(MinecraftAccount newAccount)
  mockMinecraftAccountCallback,
}) {
  test(
    'saves and returns the account correctly on success when there are no accounts previously',
    () async {
      final mockAccountStorage = mockAccountStorageProvider();

      when(
        () => mockAccountStorage.loadAccounts(),
      ).thenReturn(MinecraftAccounts.empty());

      final newAccount = MinecraftAccount(
        id: 'player-id',
        username: 'player_username',
        accountType: AccountType.microsoft,
        microsoftAccountInfo: MicrosoftAccountInfo(
          microsoftOAuthAccessToken: ExpirableToken(
            value: 'microsoft-access-token',
            expiresAt: DateTime(2025, 1, 20, 15, 40),
          ),
          microsoftOAuthRefreshToken: 'microsoft-refresh-token',
          minecraftAccessToken: ExpirableToken(
            value: 'minecraft-access-token',
            expiresAt: DateTime(2022, 1, 20, 15, 40),
          ),
        ),
        skins: const [
          MinecraftSkin(
            id: 'id',
            state: 'ACTIVE',
            url: 'http://dasdsas',
            textureKey: 'dasdsadsadsa',
            variant: MinecraftSkinVariant.classic,
          ),
          MinecraftSkin(
            id: 'iadsadasd',
            state: 'INACTIVE',
            url: 'http://dasddsadsasas',
            textureKey: 'dsad2sadsadsa',
            variant: MinecraftSkinVariant.slim,
          ),
        ],
        ownsMinecraftJava: true,
      );

      mockMinecraftAccountCallback(newAccount);

      final result = await action();

      if (result == null) {
        fail('The result should not be fails when logging using auth code');
      }

      verify(() => mockAccountStorage.loadAccounts()).called(1);
      verify(
        () => mockAccountStorage.saveAccounts(result.updatedAccounts),
      ).called(1);
      verifyNoMoreInteractions(mockAccountStorage);

      expect(result.updatedAccounts.all.length, 1);
      expect(
        result.updatedAccounts.toComparableJson(),
        MinecraftAccounts(
          all: [newAccount],
          defaultAccountId: newAccount.id,
        ).toComparableJson(),
      );
      expect(
        result.newAccount.toComparableJson(),
        newAccount.toComparableJson(),
      );
    },
  );

  test(
    'saves and returns the account correctly on success when there are accounts previously',
    () async {
      final mockAccountStorage = mockAccountStorageProvider();

      const currentDefaultAccountId = 'player-id2';
      final existingAccounts = MinecraftAccounts(
        all: [
          const MinecraftAccount(
            id: 'player-id2',
            username: 'player_username2',
            accountType: AccountType.offline,
            microsoftAccountInfo: null,
            skins: [],
            ownsMinecraftJava: true,
          ),
          MinecraftAccount(
            id: 'player-id',
            username: 'player_username',
            accountType: AccountType.microsoft,
            microsoftAccountInfo: MicrosoftAccountInfo(
              microsoftOAuthAccessToken: ExpirableToken(
                value: 'microsoft-access-token',
                expiresAt: DateTime(2099, 1, 20, 15, 40),
              ),
              microsoftOAuthRefreshToken: 'microsoft-refresh-token',
              minecraftAccessToken: ExpirableToken(
                value: 'minecraft-access-token',
                expiresAt: DateTime(2022, 1, 25, 15, 40),
              ),
            ),
            skins: const [
              MinecraftSkin(
                id: 'id',
                state: 'ACTIVE',
                url: 'http://dasdsas',
                textureKey: 'dasdsadsadsa',
                variant: MinecraftSkinVariant.classic,
              ),
              MinecraftSkin(
                id: 'iadsadasd',
                state: 'INACTIVE',
                url: 'http://dasddsadsasas',
                textureKey: 'dsad2sadsadsa',
                variant: MinecraftSkinVariant.slim,
              ),
            ],
            ownsMinecraftJava: true,
          ),
        ],
        defaultAccountId: currentDefaultAccountId,
      );

      when(
        () => mockAccountStorage.loadAccounts(),
      ).thenReturn(existingAccounts);

      final newAccount = MinecraftAccount(
        id: 'player-id3',
        username: 'player_username3',
        accountType: AccountType.microsoft,
        microsoftAccountInfo: MicrosoftAccountInfo(
          microsoftOAuthAccessToken: ExpirableToken(
            value: 'dsadsadsamicrosoft-access-token',
            expiresAt: DateTime(2024, 1, 20, 15, 40),
          ),
          microsoftOAuthRefreshToken: 'microsoftdsadsa-refresh-token',
          minecraftAccessToken: ExpirableToken(
            value: 'midsadsanecraft-access-token',
            expiresAt: DateTime(2023, 1, 21, 15, 40),
          ),
        ),
        skins: const [
          MinecraftSkin(
            id: 'iadsadasd',
            state: 'INACTIVE',
            url: 'http://dasddsadsasas',
            textureKey: 'dsad2sadsadsa',
            variant: MinecraftSkinVariant.slim,
          ),
        ],
        ownsMinecraftJava: false,
      );

      mockMinecraftAccountCallback(newAccount);

      final result = await action();

      if (result == null) {
        fail('The result should not be fails when logging using auth code');
      }

      verify(() => mockAccountStorage.loadAccounts()).called(1);
      verify(
        () => mockAccountStorage.saveAccounts(result.updatedAccounts),
      ).called(1);
      verifyNoMoreInteractions(mockAccountStorage);

      expect(
        result.updatedAccounts.all.length,
        existingAccounts.all.length + 1,
      );

      expect(
        result.updatedAccounts.toComparableJson(),
        MinecraftAccounts(
          all: [newAccount, ...existingAccounts.all],
          defaultAccountId: currentDefaultAccountId,
        ).toComparableJson(),
      );
      expect(
        result.newAccount.toComparableJson(),
        newAccount.toComparableJson(),
      );
    },
  );

  test(
    'updates and returns the existing account on success when there are accounts previously',
    () async {
      final mockAccountStorage = mockAccountStorageProvider();

      const existingAccountId = 'minecraft-id';
      final existingAccounts = MinecraftAccounts(
        all: [
          MinecraftAccount(
            id: existingAccountId,
            username: 'username',
            accountType: AccountType.microsoft,
            microsoftAccountInfo: MicrosoftAccountInfo(
              microsoftOAuthAccessToken: ExpirableToken(
                value: 'value',
                expiresAt: DateTime(2050, 2, 1, 12, 20, 0),
              ),
              microsoftOAuthRefreshToken: '',
              minecraftAccessToken: ExpirableToken(
                value: 'value',
                expiresAt: DateTime(2077, 1, 1, 12, 20, 0),
              ),
            ),
            skins: const [],
            ownsMinecraftJava: false,
          ),
          const MinecraftAccount(
            id: 'dsaiodjosajdoiska',
            username: 'username_2',
            accountType: AccountType.offline,
            microsoftAccountInfo: null,
            skins: [],
            ownsMinecraftJava: true,
          ),
        ],
        defaultAccountId: 'default-account-id',
      );

      when(
        () => mockAccountStorage.loadAccounts(),
      ).thenReturn(existingAccounts);

      final newAccount = MinecraftAccount(
        id: existingAccountId,
        username: 'username',
        accountType: AccountType.microsoft,
        microsoftAccountInfo: MicrosoftAccountInfo(
          microsoftOAuthAccessToken: ExpirableToken(
            value: 'value2',
            expiresAt: DateTime(2013, 1, 1, 20, 20, 0),
          ),
          microsoftOAuthRefreshToken: '',
          minecraftAccessToken: ExpirableToken(
            value: 'asvalue11',
            expiresAt: DateTime(2006, 3, 28, 0, 0, 0),
          ),
        ),
        skins: const [],
        ownsMinecraftJava: true,
      );

      mockMinecraftAccountCallback(newAccount);

      final result = await action();

      if (result == null) {
        fail('The result should not be fails when logging using auth code');
      }

      verify(() => mockAccountStorage.loadAccounts()).called(1);
      verify(
        () => mockAccountStorage.saveAccounts(result.updatedAccounts),
      ).called(1);
      verifyNoMoreInteractions(mockAccountStorage);

      expect(result.updatedAccounts.all.length, existingAccounts.all.length);

      final existingAccountIndex = existingAccounts.all.indexWhere(
        (account) => account.id == existingAccountId,
      );

      expect(
        result.updatedAccounts.toComparableJson(),
        existingAccounts
            .copyWith(
              all: existingAccounts.all..[existingAccountIndex] = newAccount,
            )
            .toComparableJson(),
      );
      expect(result.newAccount.id, existingAccountId);
    },
  );
}

class MockImageCacheService extends Mock implements ImageCacheService {}

extension _MinecraftAccountListExt on List<MinecraftAccount> {
  List<MinecraftAccount> updateById(
    String accountId,
    MinecraftAccount newAccount,
  ) {
    final index = indexWhere((account) => account.id == accountId);
    final newAccounts = List<MinecraftAccount>.from(this)..[index] = newAccount;
    return newAccounts;
  }
}
