import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kraft_launcher/account/data/account_storage/account_storage.dart';
import 'package:kraft_launcher/account/data/microsoft_auth_api/microsoft_auth_api.dart';
import 'package:kraft_launcher/account/data/microsoft_auth_api/microsoft_auth_exceptions.dart'
    show MicrosoftAuthException;
import 'package:kraft_launcher/account/data/minecraft_account.dart';
import 'package:kraft_launcher/account/data/minecraft_accounts.dart';
import 'package:kraft_launcher/account/data/minecraft_api/minecraft_api.dart';
import 'package:kraft_launcher/account/data/minecraft_api/minecraft_api_exceptions.dart'
    show MinecraftApiException;
import 'package:kraft_launcher/account/logic/account_manager/async_timer.dart';
import 'package:kraft_launcher/account/logic/account_manager/minecraft_account_manager.dart';
import 'package:kraft_launcher/account/logic/account_manager/minecraft_account_manager_exceptions.dart';
import 'package:kraft_launcher/common/constants/microsoft_constants.dart';
import 'package:kraft_launcher/common/logic/dio_client.dart';
import 'package:kraft_launcher/common/logic/json.dart';
import 'package:mocktail/mocktail.dart';
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

  setUp(() {
    mockMicrosoftAuthApi = MockMicrosoftAuthApi();
    mockMinecraftApi = MockMinecraftApi();
    mockAccountStorage = MockAccountStorage();
    minecraftAccountManager = MinecraftAccountManager(
      minecraftApi: mockMinecraftApi,
      microsoftAuthApi: mockMicrosoftAuthApi,

      accountStorage: mockAccountStorage,
    );
  });

  // START: Auth code

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
        registerFallbackValue(MinecraftAccounts.empty());
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
        when(
          () => mockMicrosoftAuthApi.getNewTokensFromRefreshToken(any()),
        ).thenAnswer(
          (_) async => const MicrosoftOauthTokenExchangeResponse(
            accessToken: '',
            expiresIn: -1,
            refreshToken: '',
          ),
        );
        when(() => mockMicrosoftAuthApi.requestXboxLiveToken(any())).thenAnswer(
          (_) async =>
              const XboxLiveAuthTokenResponse(xboxToken: '', userHash: ''),
        );
        when(() => mockMicrosoftAuthApi.requestXSTSToken(any())).thenAnswer(
          (_) async =>
              const XboxLiveAuthTokenResponse(xboxToken: '', userHash: ''),
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
        when(
          () => mockAccountStorage.loadAccounts(),
        ).thenAnswer((_) => MinecraftAccounts.empty());
        when(() => mockAccountStorage.saveAccounts(any())).thenDoNothing();
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

        // TODO: Maybe use simulateAuthCodeRedirect for this and the others?
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
        OnAuthProgressUpdateCallback? onProgressUpdate,
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
            successLoginPageContent: successPageContent(),
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

          // TODO: Avoid passing fakeAuthCode if we don't need it for this and the others
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

      test(
        'throws $MinecraftApiAccountManagerException on $MinecraftApiException',
        () async {
          final minecraftApiException = MinecraftApiException.tooManyRequests();
          when(
            () => mockMinecraftApi.fetchMinecraftProfile(any()),
          ).thenAnswer((_) async => throw minecraftApiException);
          await expectLater(
            simulateAuthCodeRedirect(),
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
          final microsoftAuthException =
              MicrosoftAuthException.authCodeExpired();
          when(
            () => mockMicrosoftAuthApi.exchangeAuthCodeForTokens(any()),
          ).thenAnswer((_) async => throw microsoftAuthException);
          await expectLater(
            simulateAuthCodeRedirect(),
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

      test('throws $Exception on $UnknownAccountManagerException', () async {
        final exception = Exception('Hello, World!');
        when(
          () => mockMicrosoftAuthApi.exchangeAuthCodeForTokens(any()),
        ).thenAnswer((_) async => throw exception);
        await expectLater(
          simulateAuthCodeRedirect(),
          throwsA(
            isA<UnknownAccountManagerException>().having(
              (e) => e.message,
              'message',
              equals(exception.toString()),
            ),
          ),
        );
      });

      // Mock the new account that will be returned from the APIs when login using
      // auth code successfully.
      void mockMinecraftAccountAsLoginResult(MinecraftAccount account) {
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
            // The launcher doesn't support managing the capes yet.
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
        when(
          () => mockMicrosoftAuthApi.exchangeAuthCodeForTokens(any()),
        ).thenAnswer(
          (_) async => MicrosoftOauthTokenExchangeResponse(
            accessToken:
                account.microsoftAccountInfo?.microsoftOAuthAccessToken.value ??
                (fail(
                  'Please provide a value for Microsoft OAuth access token',
                )),
            refreshToken:
                account.microsoftAccountInfo?.microsoftOAuthRefreshToken ??
                (fail(
                  'Please provide a value for Microsoft OAuth refresh token',
                )),
            expiresIn:
                account
                    .microsoftAccountInfo
                    ?.microsoftOAuthAccessToken
                    .expiresAt
                    .covertToExpiresIn ??
                (fail(
                  'Please provide a value for Microsoft OAuth access token expires in',
                )),
          ),
        );
      }

      test(
        'saves and returns the account correctly on success when there are no accounts previously',
        () async {
          when(
            () => mockAccountStorage.loadAccounts(),
          ).thenAnswer((_) => MinecraftAccounts.empty());

          final newAccount = MinecraftAccount(
            id: 'player-id',
            username: 'player_username',
            accountType: AccountType.microsoft,
            microsoftAccountInfo: MicrosoftAccountInfo(
              microsoftOAuthAccessToken: ExpirableToken(
                value: 'microsoft-access-token',
                expiresAt: DateTime.now().add(const Duration(days: 4)),
              ),
              microsoftOAuthRefreshToken: 'microsoft-refresh-token',
              minecraftAccessToken: ExpirableToken(
                value: 'minecraft-access-token',
                expiresAt: DateTime.now().add(const Duration(hours: 20)),
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

          mockMinecraftAccountAsLoginResult(newAccount);

          final (result, _) = await simulateAuthCodeRedirect();

          verify(() => mockAccountStorage.loadAccounts()).called(1);
          verify(() => mockAccountStorage.saveAccounts(any())).called(1);
          verifyNoMoreInteractions(mockAccountStorage);

          expect(result?.updatedAccounts.all.length, 1);
          expect(
            result?.updatedAccounts.toComparableJson(),
            MinecraftAccounts(
              all: [newAccount],
              defaultAccountId: newAccount.id,
            ).toComparableJson(),
          );
          expect(
            result?.newAccount.toComparableJson(),
            newAccount.toComparableJson(),
          );
        },
      );

      test(
        'saves and returns the account correctly on success when there are accounts previously',
        () async {
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
                    expiresAt: DateTime.now().add(const Duration(days: 4)),
                  ),
                  microsoftOAuthRefreshToken: 'microsoft-refresh-token',
                  minecraftAccessToken: ExpirableToken(
                    value: 'minecraft-access-token',
                    expiresAt: DateTime.now().add(const Duration(hours: 20)),
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
          ).thenAnswer((_) => existingAccounts);

          final newAccount = MinecraftAccount(
            id: 'player-id3',
            username: 'player_username3',
            accountType: AccountType.microsoft,
            microsoftAccountInfo: MicrosoftAccountInfo(
              microsoftOAuthAccessToken: ExpirableToken(
                value: 'dsadsadsamicrosoft-access-token',
                expiresAt: DateTime.now().add(const Duration(days: 1)),
              ),
              microsoftOAuthRefreshToken: 'microsoftdsadsa-refresh-token',
              minecraftAccessToken: ExpirableToken(
                value: 'midsadsanecraft-access-token',
                expiresAt: DateTime.now().add(const Duration(hours: 120)),
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

          mockMinecraftAccountAsLoginResult(newAccount);

          final (result, _) = await simulateAuthCodeRedirect();

          verify(() => mockAccountStorage.loadAccounts()).called(1);
          verify(() => mockAccountStorage.saveAccounts(any())).called(1);
          verifyNoMoreInteractions(mockAccountStorage);

          expect(
            result?.updatedAccounts.all.length,
            existingAccounts.all.length + 1,
          );

          expect(
            result?.updatedAccounts.toComparableJson(),
            MinecraftAccounts(
              all: [newAccount, ...existingAccounts.all],
              defaultAccountId: currentDefaultAccountId,
            ).toComparableJson(),
          );
          expect(
            result?.newAccount.toComparableJson(),
            newAccount.toComparableJson(),
          );
        },
      );

      test(
        'updates and returns the existing account on success when there are accounts previously',
        () async {
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
          ).thenAnswer((_) => existingAccounts);

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
          mockMinecraftAccountAsLoginResult(newAccount);

          final (result, _) = await simulateAuthCodeRedirect();

          verify(() => mockAccountStorage.loadAccounts()).called(1);
          verify(() => mockAccountStorage.saveAccounts(any())).called(1);
          verifyNoMoreInteractions(mockAccountStorage);

          expect(
            result?.updatedAccounts.all.length,
            existingAccounts.all.length,
          );

          final existingAccountIndex = existingAccounts.all.indexWhere(
            (account) => account.id == existingAccountId,
          );

          expect(
            result?.updatedAccounts.toComparableJson(),
            existingAccounts
                .copyWith(
                  all:
                      existingAccounts.all..[existingAccountIndex] = newAccount,
                )
                .toComparableJson(),
          );
          expect(result?.newAccount.id, existingAccountId);
        },
      );
    });

    // TODO: Tests for verifing the default account id when removing an account, it should remain the same if this is not the default account that was deleted, otherwise navigate to after or before or null
  });
}

// TODO: This test is a WIP! Once auth code flow tests is done, we should also
// start covering device code flow from zero, even if the file says it's covered!

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
