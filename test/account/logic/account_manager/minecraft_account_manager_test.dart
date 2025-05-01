import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kraft_launcher/account/data/account_storage/account_storage.dart';
import 'package:kraft_launcher/account/data/microsoft_auth_api/microsoft_auth_api.dart';
import 'package:kraft_launcher/account/data/minecraft_api/minecraft_api.dart';
import 'package:kraft_launcher/account/logic/account_manager/async_timer.dart';
import 'package:kraft_launcher/account/logic/account_manager/minecraft_account_manager.dart';
import 'package:kraft_launcher/account/logic/account_manager/minecraft_account_manager_exceptions.dart';
import 'package:kraft_launcher/common/constants/microsoft_constants.dart';
import 'package:kraft_launcher/common/logic/app_data_paths.dart';
import 'package:kraft_launcher/common/logic/dio_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../../common/helpers/dio_utils.dart';
import '../../../common/helpers/temp_file_utils.dart';
import '../../../common/helpers/url_launcher_utils.dart';
import '../../../common/helpers/utils.dart';

class MockMicrosoftAuthApi extends Mock implements MicrosoftAuthApi {}

class MockMinecraftApi extends Mock implements MinecraftApi {}

void main() {
  late AppDataPaths appDataPaths;
  late MockMicrosoftAuthApi mockMicrosoftAuthApi;
  late MockMinecraftApi mockMinecraftApi;
  late MinecraftAccountManager minecraftAccountManager;

  setUp(() {
    mockMicrosoftAuthApi = MockMicrosoftAuthApi();
    mockMinecraftApi = MockMinecraftApi();
    appDataPaths = AppDataPaths(workingDirectory: createTempTestDir());
    minecraftAccountManager = MinecraftAccountManager(
      minecraftApi: mockMinecraftApi,
      microsoftAuthApi: mockMicrosoftAuthApi,

      accountStorage: AccountStorage.fromAppDataPaths(appDataPaths),
    );
  });

  tearDown(() {
    appDataPaths.workingDirectory.deleteSync(recursive: true);
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

      test('responds with HTML page and closes server on success', () async {
        String? response;
        final getRequestCompleter = Completer<void>();
        unawaited(
          Future<void>.delayed(Duration.zero).then((_) async {
            response =
                (await DioTestClient.instance.getUri<String>(
                  serverUri(codeCodeParam: fakeAuthCode),
                )).dataOrThrow;
            getRequestCompleter.complete();
          }),
        );
        final successLoginPageContent = successPageContent();
        bool reachedExchangingAuthCodeProgress = false;
        await minecraftAccountManager.loginWithMicrosoftAuthCode(
          onProgressUpdate: (progress, {authCodeLoginUrl}) async {
            if (progress == MicrosoftAuthProgress.exchangingAuthCode) {
              reachedExchangingAuthCodeProgress = true;
            }
          },
          successLoginPageContent: successLoginPageContent,
        );
        expect(reachedExchangingAuthCodeProgress, true);
        expect(minecraftAccountManager.isServerRunning, false);

        await getRequestCompleter.future.timeout(const Duration(seconds: 5));
        expect(response, buildAuthCodeSuccessPageHtml(successLoginPageContent));

        // Passes auth code correctly to Microsoft API
        verify(
          () => mockMicrosoftAuthApi.exchangeAuthCodeForTokens(fakeAuthCode),
        ).called(1);
      });

      test(
        'completes full auth code flow from Microsoft OAuth access token to Minecraft profile',
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

          final getRequestCompleter = Completer<void>();
          unawaited(
            Future<void>.delayed(Duration.zero).then((_) async {
              await DioTestClient.instance.getUri<String>(
                serverUri(codeCodeParam: fakeAuthCode),
              );
              getRequestCompleter.complete();
            }),
          );

          final progressList = <MicrosoftAuthProgress>[];
          final successLoginPageContent = successPageContent();
          // TODO: Handle response?
          // TODO: Extract common login Microsoft into a seprate class to make it easier for testing
          await minecraftAccountManager.loginWithMicrosoftAuthCode(
            onProgressUpdate: (progress, {authCodeLoginUrl}) async {
              progressList.add(progress);
            },
            successLoginPageContent: successLoginPageContent,
          );

          await getRequestCompleter.future.timeout(const Duration(seconds: 5));

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
        },
      );
    });
  });
}

// TODO: This test is a WIP!
