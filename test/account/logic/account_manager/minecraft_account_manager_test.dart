void main() {}

// import 'dart:async';

// import 'package:clock/clock.dart';
// import 'package:fake_async/fake_async.dart';
// import 'package:kraft_launcher/account/data/microsoft_auth_api/auth_methods/microsoft_device_code_flow.dart';
// import 'package:kraft_launcher/account/data/microsoft_auth_api/microsoft_auth_api.dart';
// import 'package:kraft_launcher/account/data/microsoft_auth_api/microsoft_auth_exceptions.dart';
// import 'package:kraft_launcher/account/data/minecraft_account/minecraft_account.dart';
// import 'package:kraft_launcher/account/data/minecraft_account/minecraft_accounts.dart';
// import 'package:kraft_launcher/account/data/minecraft_api/minecraft_api.dart';
// import 'package:kraft_launcher/account/data/minecraft_api/minecraft_api_exceptions.dart';
// import 'package:kraft_launcher/account/logic/account_manager/async_timer.dart';
// import 'package:kraft_launcher/account/logic/account_manager/image_cache_service/image_cache_service.dart';
// import 'package:kraft_launcher/account/logic/account_manager/minecraft_account_manager.dart';
// import 'package:kraft_launcher/account/logic/account_manager/minecraft_account_manager_exceptions.dart';
// import 'package:kraft_launcher/account/logic/account_repository.dart';
// import 'package:kraft_launcher/account/logic/account_utils.dart';
// import 'package:kraft_launcher/account/logic/minecraft_skin_ext.dart';
// import 'package:kraft_launcher/common/constants/constants.dart';
// import 'package:kraft_launcher/common/logic/dio_client.dart';
// import 'package:kraft_launcher/common/logic/json.dart';
// import 'package:kraft_launcher/common/logic/utils.dart';
// import 'package:mocktail/mocktail.dart';
// import 'package:test/test.dart';
// import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

// import '../../../common/helpers/dio_utils.dart';
// import '../../../common/helpers/url_launcher_utils.dart';
// import '../../../common/helpers/utils.dart';
// import '../../data/minecraft_account_utils.dart';
// import '../../data/minecraft_dummy_accounts.dart';

// class _MockMicrosoftAuthApi extends Mock implements MicrosoftAuthApi {}

// class _MockMinecraftApi extends Mock implements MinecraftApi {}

// class _MockAccountRepository extends Mock implements AccountRepository {}

// late _MockMicrosoftAuthApi _mockMicrosoftAuthApi;
// late _MockMinecraftApi _mockMinecraftApi;
// late _MockAccountRepository _mockAccountRepository;
// late MockImageCacheService _mockImageCacheService;

// late MinecraftAccountManager _minecraftAccountManager;

// // TODO: This test file is a total mess, should we refactor it fully? Make refactoring to existing production code to improve testability first.
// // TODO: Improve CI performance by avoiding all IO and Network operations in unit tests,
// //  move them to integration_test and depend on mocking instead:
// //  1. Avoid starting HttpServer and sending http requests to the local server in auth code flow in this file.
// //  2. Avoid creating files temporarily in unit tests, to track them, see usages of functions inside temp_file_utils.dart
// //  3. We compare the accounts before and after to ensure the action applied the modification correctly, and that's done using toJson() to avoid the need for overriding hashCode and == or equatable,
// //     however, the comparison between expiration dates could be improved or we might need to refactor this approach to solve it in a better way.

// // TODO: The tests of this file are broken due to refactoring and AccountRepository,
// //  we will fix it once we're done with some refactoring in MinecraftAccountManager, AccountCubit and MicrosoftAccountHandlerCubit.

// void main() {
//   setUp(() {
//     _mockMicrosoftAuthApi = _MockMicrosoftAuthApi();
//     _mockMinecraftApi = _MockMinecraftApi();
//     _mockAccountRepository = _MockAccountRepository();
//     _mockImageCacheService = MockImageCacheService();
//     _minecraftAccountManager = MinecraftAccountManager(
//       minecraftApi: _mockMinecraftApi,
//       microsoftAuthApi: _mockMicrosoftAuthApi,
//       accountRepository: _mockAccountRepository,
//       imageCacheService: _mockImageCacheService,
//     );

//     when(
//       () => _mockAccountRepository.loadAccounts(),
//     ).thenAnswer((_) async => MinecraftAccounts.empty());

//     when(
//       () => _mockAccountRepository.addAccount(any()),
//     ).thenAnswer((_) async {});

//     when(
//       () => _mockAccountRepository.updateAccount(any()),
//     ).thenAnswer((_) async {});

//     when(
//       () => _mockAccountRepository.removeAccount(any()),
//     ).thenAnswer((_) async {});

//     when(
//       () => _mockAccountRepository.updateDefaultAccount(any()),
//     ).thenAnswer((_) async {});

//     when(
//       () => _mockAccountRepository.accountExists(any()),
//     ).thenAnswer((_) => true);

//     when(() => _mockMicrosoftAuthApi.requestXboxLiveToken(any())).thenAnswer(
//       (_) async => const XboxLiveAuthTokenResponse(xboxToken: '', userHash: ''),
//     );
//     when(() => _mockMicrosoftAuthApi.requestXSTSToken(any())).thenAnswer(
//       (_) async => const XboxLiveAuthTokenResponse(xboxToken: '', userHash: ''),
//     );
//     when(
//       () => _mockMinecraftApi.checkMinecraftJavaOwnership(any()),
//     ).thenAnswer((_) async => true);
//     when(() => _mockMinecraftApi.fetchMinecraftProfile(any())).thenAnswer(
//       (_) async => const MinecraftProfileResponse(
//         id: '',
//         name: '',
//         skins: [],
//         capes: [],
//       ),
//     );
//     when(() => _mockMinecraftApi.loginToMinecraftWithXbox(any())).thenAnswer(
//       (_) async => const MinecraftLoginResponse(
//         username: '',
//         accessToken: '',
//         expiresIn: -1,
//       ),
//     );
//   });

//   // Mock the new account that will be returned from the APIs whether it's
//   // using device code, auth code or refreshing the account. This will mock the API
//   // responses that are used to build the Minecraft account and always assumes success.
//   void mockLoginResult(
//     MinecraftAccount account, {
//     required _TestAuthAction authAction,
//     required ExpirableToken microsoftAccessToken,
//   }) {
//     MinecraftApiCosmeticState cosmeticStateToApi(
//       MinecraftCosmeticState state,
//     ) => switch (state) {
//       MinecraftCosmeticState.active => MinecraftApiCosmeticState.active,
//       MinecraftCosmeticState.inactive => MinecraftApiCosmeticState.inactive,
//     };
//     when(() => _mockMinecraftApi.fetchMinecraftProfile(any())).thenAnswer(
//       (_) async => MinecraftProfileResponse(
//         id: account.id,
//         name: account.username,
//         skins:
//             account.skins
//                 .map(
//                   (skin) => MinecraftProfileSkin(
//                     id: skin.id,
//                     state: cosmeticStateToApi(skin.state),
//                     textureKey: skin.textureKey,
//                     url: skin.url,
//                     variant: switch (skin.variant) {
//                       MinecraftSkinVariant.classic =>
//                         MinecraftApiSkinVariant.classic,
//                       MinecraftSkinVariant.slim => MinecraftApiSkinVariant.slim,
//                     },
//                   ),
//                 )
//                 .toList(),
//         capes:
//             account.capes
//                 .map(
//                   (cape) => MinecraftProfileCape(
//                     id: cape.id,
//                     state: cosmeticStateToApi(cape.state),
//                     url: cape.url,
//                     alias: cape.alias,
//                   ),
//                 )
//                 .toList(),
//       ),
//     );

//     when(
//       () => _mockMinecraftApi.checkMinecraftJavaOwnership(any()),
//     ).thenAnswer((_) async => account.ownsMinecraftJava ?? false);
//     when(() => _mockMinecraftApi.loginToMinecraftWithXbox(any())).thenAnswer(
//       (_) async => MinecraftLoginResponse(
//         accessToken:
//             account.microsoftAccountInfo?.minecraftAccessToken.value ??
//             (fail('Please provide a value for minecraft access token')),
//         username: account.username,
//         expiresIn:
//             account
//                 .microsoftAccountInfo
//                 ?.minecraftAccessToken
//                 .expiresAt
//                 .covertToExpiresIn ??
//             (fail(
//               'Please provide a value for minecraft access token expires in',
//             )),
//       ),
//     );

//     MicrosoftOauthTokenExchangeResponse response() =>
//         MicrosoftOauthTokenExchangeResponse(
//           accessToken:
//               microsoftAccessToken.value ??
//               (fail('Please provide a value for Microsoft OAuth access token')),
//           refreshToken:
//               account.microsoftAccountInfo?.microsoftOAuthRefreshToken.value ??
//               (fail(
//                 'Please provide a value for Microsoft OAuth refresh token',
//               )),
//           expiresIn: microsoftAccessToken.expiresAt.covertToExpiresIn,
//         );
//     switch (authAction) {
//       case _TestAuthAction.refreshAccount:
//         when(
//           () => _mockMicrosoftAuthApi.getNewTokensFromRefreshToken(any()),
//         ).thenAnswer((_) async => response());
//       case _TestAuthAction.loginWithAuthCode:
//         when(
//           () => _mockMicrosoftAuthApi.exchangeAuthCodeForTokens(any()),
//         ).thenAnswer((_) async => response());
//       case _TestAuthAction.loginWithDeviceCode:
//         when(
//           () => _mockMicrosoftAuthApi.checkDeviceCodeStatus(any()),
//         ).thenAnswer(
//           (_) async =>
//               MicrosoftCheckDeviceCodeStatusResult.approved(response()),
//         );
//     }
//   }

//   setUpAll(() {
//     registerFallbackValue(MinecraftAccounts.empty());
//     registerFallbackValue(
//       const MicrosoftOauthTokenExchangeResponse(
//         accessToken: '',
//         expiresIn: -1,
//         refreshToken: '',
//       ),
//     );
//     registerFallbackValue(
//       const XboxLiveAuthTokenResponse(userHash: '', xboxToken: ''),
//     );
//   });

//   group('auth code flow', () {
//     tearDown(() async {
//       if (_minecraftAccountManager.isServerRunning) {
//         await _minecraftAccountManager.stopServer();
//       }
//     });

//     test('requireServer throws $StateError if null', () {
//       expect(() => _minecraftAccountManager.requireServer, throwsStateError);
//     });

//     test('requireServer returns httpServer if not null', () async {
//       final server = await _minecraftAccountManager.startServer();
//       expect(_minecraftAccountManager.requireServer, server);
//     });

//     test('isServerRunning returns correctly', () async {
//       await _minecraftAccountManager.startServer();
//       expect(_minecraftAccountManager.isServerRunning, true);

//       await _minecraftAccountManager.stopServer();
//       expect(_minecraftAccountManager.isServerRunning, false);
//     });

//     test(
//       'httpServer initially null',
//       () => expect(_minecraftAccountManager.httpServer, null),
//     );

//     test('startServer sets httpServer to not null', () async {
//       expect(
//         await _minecraftAccountManager.startServer(),
//         _minecraftAccountManager.httpServer,
//       );
//       expect(_minecraftAccountManager.httpServer, isNotNull);
//     });

//     test('stopServer sets httpServer to null', () async {
//       await _minecraftAccountManager.startServer();
//       await _minecraftAccountManager.stopServer();
//       expect(_minecraftAccountManager.httpServer, null);
//     });
//     test('stopServerIfRunning stops the server if it is running', () async {
//       await _minecraftAccountManager.startServer();

//       expect(await _minecraftAccountManager.stopServerIfRunning(), true);
//     });
//     test('stopServerIfRunning do thing if', () async {
//       expect(await _minecraftAccountManager.stopServerIfRunning(), false);
//     });

//     (String, int) addressAndPort() => (
//       _minecraftAccountManager.requireServer.address.address,
//       _minecraftAccountManager.requireServer.port,
//     );

//     Uri serverUri({
//       required String? codeCodeParam,
//       String? errorCodeParam,
//       String? errorDescriptionParam,
//     }) {
//       final (address, port) = addressAndPort();
//       return Uri.http('$address:$port', '/', {
//         if (codeCodeParam != null)
//           MicrosoftConstants.loginRedirectAuthCodeQueryParamName: codeCodeParam,
//         if (errorCodeParam != null)
//           MicrosoftConstants.loginRedirectErrorQueryParamName: errorCodeParam,
//         if (errorDescriptionParam != null)
//           MicrosoftConstants.loginRedirectErrorDescriptionQueryParamName:
//               errorDescriptionParam,
//       });
//     }

//     test('server is reachable when started', () async {
//       await _minecraftAccountManager.startServer();
//       expect(_minecraftAccountManager.isServerRunning, true);

//       final (address, port) = addressAndPort();
//       expect(await isPortOpen(address, port), true);
//       await _minecraftAccountManager.stopServer();
//     });

//     test('server is not reachable when stopped', () async {
//       await _minecraftAccountManager.startServer();

//       final (address, port) = addressAndPort();

//       await _minecraftAccountManager.stopServer();
//       expect(_minecraftAccountManager.isServerRunning, false);

//       expect(await isPortOpen(address, port), false);
//     });

//     group('loginWithMicrosoftAuthCode', () {
//       // NOTE: These tests start a minimal localhost HTTP server and send
//       // real GET requests to it. As a result, they're not pure unit tests.

//       late MockUrlLauncher mockUrlLauncher;

//       setUpAll(() {
//         registerFallbackValue(dummyLauncherOptions());
//       });

//       setUp(() {
//         mockUrlLauncher = MockUrlLauncher();
//         UrlLauncherPlatform.instance = mockUrlLauncher;
//         when(
//           () => mockUrlLauncher.launchUrl(any(), any()),
//         ).thenAnswer((_) async => false);
//         when(
//           () => _mockMicrosoftAuthApi.userLoginUrlWithAuthCode(),
//         ).thenReturn('');
//         when(
//           () => _mockMicrosoftAuthApi.exchangeAuthCodeForTokens(any()),
//         ).thenAnswer(
//           (_) async => const MicrosoftOauthTokenExchangeResponse(
//             accessToken: '',
//             expiresIn: -1,
//             refreshToken: '',
//           ),
//         );
//       });

//       MicrosoftAuthCodeResponsePageContent authCodeResponsePageContent({
//         String pageTitle = '',
//         String title = '',
//         String subtitle = '',
//         String pageLangCode = '',
//         String pageDir = '',
//       }) => MicrosoftAuthCodeResponsePageContent(
//         pageTitle: pageTitle,
//         title: title,
//         subtitle: subtitle,
//         pageLangCode: pageLangCode,
//         pageDir: pageDir,
//       );

//       MicrosoftAuthCodeResponsePageVariants authCodeResponsePageVariants({
//         MicrosoftAuthCodeResponsePageContent? approved,
//         MicrosoftAuthCodeResponsePageContent? accessDenied,
//         MicrosoftAuthCodeResponsePageContent? missingAuthCode,
//         MicrosoftAuthCodeResponsePageContent Function(
//           String errorCode,
//           String errorDescription,
//         )?
//         unknownError,
//       }) => MicrosoftAuthCodeResponsePageVariants(
//         accessDenied: accessDenied ?? authCodeResponsePageContent(),
//         approved: approved ?? authCodeResponsePageContent(),
//         missingAuthCode: missingAuthCode ?? authCodeResponsePageContent(),
//         unknownError:
//             unknownError ??
//             (errorCode, errorDescription) => authCodeResponsePageContent(),
//       );

//       Future<AccountResult?> loginWithMicrosoftAuthCode({
//         OnAuthProgressUpdateAuthCodeCallback? onProgressUpdate,
//         MicrosoftAuthCodeResponsePageVariants? responsePageVariants,
//       }) => _minecraftAccountManager.loginWithMicrosoftAuthCode(
//         onProgressUpdate: onProgressUpdate ?? (_, {authCodeLoginUrl}) {},
//         authCodeResponsePageVariants:
//             responsePageVariants ?? authCodeResponsePageVariants(),
//       );

//       test('starts server if not started already', () async {
//         expect(_minecraftAccountManager.isServerRunning, false);

//         unawaited(loginWithMicrosoftAuthCode());

//         // Waiting for the server to start
//         await Future<void>.delayed(Duration.zero);
//         expect(_minecraftAccountManager.isServerRunning, true);

//         await _minecraftAccountManager.stopServer();
//       });

//       test('opens the correct URL after starting the server', () async {
//         const authCodeLoginUrl = 'https://example.com/login/oauth2/callback';

//         when(
//           () => mockUrlLauncher.launchUrl(authCodeLoginUrl, any()),
//         ).thenAnswer((_) async => true);
//         when(
//           () => _mockMicrosoftAuthApi.userLoginUrlWithAuthCode(),
//         ).thenReturn(authCodeLoginUrl);

//         unawaited(loginWithMicrosoftAuthCode());

//         // Waiting for the server to start
//         await Future<void>.delayed(Duration.zero);
//         verify(
//           () => mockUrlLauncher.launchUrl(authCodeLoginUrl, any()),
//         ).called(1);
//         verifyNoMoreInteractions(mockUrlLauncher);

//         verify(
//           () => _mockMicrosoftAuthApi.userLoginUrlWithAuthCode(),
//         ).called(1);
//         verifyNoMoreInteractions(_mockMicrosoftAuthApi);

//         await _minecraftAccountManager.stopServer();
//       });

//       test('calls onProgressUpdate with the login URL', () async {
//         const authCodeLoginUrl = 'https://example.com/login/oauth2/callback';

//         String? capturedLoginUrl;
//         when(
//           () => _mockMicrosoftAuthApi.userLoginUrlWithAuthCode(),
//         ).thenReturn(authCodeLoginUrl);

//         unawaited(
//           loginWithMicrosoftAuthCode(
//             onProgressUpdate: (progress, {authCodeLoginUrl}) {
//               capturedLoginUrl = authCodeLoginUrl;
//               if (progress != MicrosoftAuthProgress.waitingForUserLogin) {
//                 fail(
//                   'Expected the progress to be ${MicrosoftAuthProgress.waitingForUserLogin.name} as this state',
//                 );
//               }
//             },
//           ),
//         );

//         // Waiting for the server to start
//         await Future<void>.delayed(Duration.zero);

//         expect(capturedLoginUrl, isNotNull);
//         expect(capturedLoginUrl, authCodeLoginUrl);

//         await _minecraftAccountManager.stopServer();
//       });

//       test('cancels device code polling timer', () async {
//         _minecraftAccountManager.deviceCodePollingTimer = AsyncTimer.periodic(
//           // This duration is a dummy value
//           const Duration(seconds: 10),
//           () {},
//         );
//         expect(_minecraftAccountManager.isDeviceCodePollingTimerActive, true);
//         expect(_minecraftAccountManager.deviceCodePollingTimer, isNotNull);

//         unawaited(loginWithMicrosoftAuthCode());
//         // Waiting for the server to start
//         await Future<void>.delayed(Duration.zero);

//         expect(_minecraftAccountManager.isDeviceCodePollingTimerActive, false);
//         expect(_minecraftAccountManager.deviceCodePollingTimer, isNull);
//         expect(
//           _minecraftAccountManager.requestCancelDeviceCodePollingTimer,
//           true,
//         );

//         await _minecraftAccountManager.stopServer();
//       });

//       const fakeAuthCode = 'M1ddasdasdsadsadsadsadsq0idqwjiod';

//       // Starts the redirect server, sends an HTTP request to it with the auth code
//       // as if the Microsoft API had redirected the user, and then returns the result.
//       Future<(AccountResult? result, String? redirectServerResponse)>
//       simulateAuthCodeRedirect({
//         String? authCode = fakeAuthCode,
//         String? errorCode,
//         String? errorDescription,
//         OnAuthProgressUpdateAuthCodeCallback? onProgressUpdate,
//         MicrosoftAuthCodeResponsePageVariants? authCodeResponsePageVariants,

//         /// Whether to return null of [AccountResult] or
//         /// ignoring exceptions thrown by [loginWithMicrosoftAuthCode] to return
//         /// only the server response.
//         bool ignoreResultExceptions = false,
//       }) async {
//         final getRequestCompleter = Completer<String?>();
//         unawaited(
//           Future<void>.delayed(Duration.zero).then((_) async {
//             try {
//               final response =
//                   (await DioTestClient.instance.getUri<String>(
//                     serverUri(
//                       codeCodeParam: authCode,
//                       errorCodeParam: errorCode,
//                       errorDescriptionParam: errorDescription,
//                     ),
//                   )).dataOrThrow;
//               getRequestCompleter.complete(response);
//             } catch (e, stackTrace) {
//               getRequestCompleter.completeError(e, stackTrace);
//             }
//           }),
//         );

//         AccountResult? result;
//         if (ignoreResultExceptions) {
//           try {
//             result = await loginWithMicrosoftAuthCode(
//               onProgressUpdate: onProgressUpdate,
//               responsePageVariants: authCodeResponsePageVariants,
//             );
//           } on Exception catch (_) {}
//         } else {
//           result = await loginWithMicrosoftAuthCode(
//             onProgressUpdate: onProgressUpdate,
//             responsePageVariants: authCodeResponsePageVariants,
//           );
//         }

//         final getRequestResponse = await getRequestCompleter.future.timeout(
//           const Duration(seconds: 1),
//         );

//         return (result, getRequestResponse);
//       }

//       // START: Unknown redirect errors

//       test(
//         'responds with unknown error HTML page and closes server when redirect error code is unknown',
//         () async {
//           const fakeErrorCode = 'unknown_error';
//           const fakeErrorDescription = 'An internal server error';
//           final pageContent = authCodeResponsePageContent(
//             title: 'An error occurred',
//             pageDir: 'rtl',
//             pageLangCode: 'de',
//             pageTitle: 'An unknown error occurred',
//             subtitle:
//                 'An unknown error occurred while logging in: $fakeErrorCode, $fakeErrorDescription',
//           );

//           final (_, response) = await simulateAuthCodeRedirect(
//             errorCode: fakeErrorCode,
//             errorDescription: fakeErrorDescription,
//             authCodeResponsePageVariants: authCodeResponsePageVariants(
//               unknownError: (errorCode, errorDescription) => pageContent,
//             ),
//             ignoreResultExceptions: true,
//           );

//           expect(_minecraftAccountManager.isServerRunning, false);

//           expect(
//             response,
//             buildAuthCodeResultHtmlPage(pageContent, isSuccess: false),
//           );
//         },
//       );

//       test(
//         'throws $MicrosoftAuthCodeRedirectAccountManagerException when redirect error code is unknown',
//         () async {
//           const fakeErrorCode = 'unknown_error';
//           const fakeErrorDescription = 'An internal server error';
//           await expectLater(
//             simulateAuthCodeRedirect(
//               authCode: null,
//               errorCode: fakeErrorCode,
//               errorDescription: fakeErrorDescription,
//             ),
//             throwsA(
//               isA<MicrosoftAuthCodeRedirectAccountManagerException>()
//                   .having((e) => e.error, 'errorCode', fakeErrorCode)
//                   .having(
//                     (e) => e.errorDescription,
//                     'errorDescription',
//                     fakeErrorDescription,
//                   ),
//             ),
//           );
//           expect(_minecraftAccountManager.isServerRunning, false);
//         },
//       );

//       // END: Unknown redirect errors

//       // START: Auth code missing redirect error

//       test(
//         'responds with auth code missing HTML page and closes server when redirect code query parameter is missing',
//         () async {
//           final pageContent = authCodeResponsePageContent(
//             title: 'The auth code query parameter is missing',
//             pageDir: 'ltr',
//             pageLangCode: 'zh',
//             pageTitle: 'Auth code is missing',
//             subtitle: 'Please restart the sign-in process.',
//           );

//           final (_, response) = await simulateAuthCodeRedirect(
//             authCode: null,
//             authCodeResponsePageVariants: authCodeResponsePageVariants(
//               missingAuthCode: pageContent,
//             ),
//             ignoreResultExceptions: true,
//           );

//           expect(_minecraftAccountManager.isServerRunning, false);

//           expect(
//             response,
//             buildAuthCodeResultHtmlPage(pageContent, isSuccess: false),
//           );
//         },
//       );

//       test(
//         'throws $MicrosoftMissingAuthCodeAccountManagerException when redirect code query parameter is missing',
//         () async {
//           await expectLater(
//             simulateAuthCodeRedirect(authCode: null),
//             throwsA(isA<MicrosoftMissingAuthCodeAccountManagerException>()),
//           );
//           expect(_minecraftAccountManager.isServerRunning, false);
//         },
//       );

//       // END: Auth code missing redirect error

//       // START: Access denied redirect error

//       test(
//         'responds with access denied HTML page and closes server when redirect error query parameter is ${MicrosoftConstants.loginRedirectAccessDeniedErrorCode}',
//         () async {
//           final pageContent = authCodeResponsePageContent(
//             title: 'The auth code query parameter is missing',
//             pageDir: 'ltr',
//             pageLangCode: 'zh',
//             pageTitle: 'Auth code is missing',
//             subtitle: 'Please restart the sign-in process.',
//           );

//           final (_, response) = await simulateAuthCodeRedirect(
//             authCode: null,
//             errorCode: MicrosoftConstants.loginRedirectAccessDeniedErrorCode,
//             authCodeResponsePageVariants: authCodeResponsePageVariants(
//               accessDenied: pageContent,
//             ),
//             ignoreResultExceptions: true,
//           );

//           expect(_minecraftAccountManager.isServerRunning, false);

//           expect(
//             response,
//             buildAuthCodeResultHtmlPage(pageContent, isSuccess: false),
//           );
//         },
//       );

//       test(
//         'throws $MicrosoftAuthCodeDeniedAccountManagerException when redirect error query parameter is ${MicrosoftConstants.loginRedirectAccessDeniedErrorCode}',
//         () async {
//           await expectLater(
//             simulateAuthCodeRedirect(
//               authCode: null,
//               errorCode: MicrosoftConstants.loginRedirectAccessDeniedErrorCode,
//             ),
//             throwsA(isA<MicrosoftAuthCodeDeniedAccountManagerException>()),
//           );
//           expect(_minecraftAccountManager.isServerRunning, false);
//         },
//       );

//       // END: Access denied redirect error

//       test(
//         'responds with success HTML page and closes server on success',
//         () async {
//           final pageContent = authCodeResponsePageContent(
//             title: 'You are logged in now!',
//             pageDir: 'ltr',
//             pageLangCode: 'en',
//             pageTitle: 'Successful Login!',
//             subtitle:
//                 'You can close this window now, the launcher is logging in...',
//           );

//           final (_, response) = await simulateAuthCodeRedirect(
//             authCode: fakeAuthCode,
//             authCodeResponsePageVariants: authCodeResponsePageVariants(
//               approved: pageContent,
//             ),
//           );

//           expect(_minecraftAccountManager.isServerRunning, false);

//           expect(
//             response,
//             buildAuthCodeResultHtmlPage(pageContent, isSuccess: true),
//           );
//         },
//       );

//       test('passes auth code correctly to exchangeAuthCodeForTokens', () async {
//         bool reachedExchangingAuthCodeProgress = false;
//         final (_, _) = await simulateAuthCodeRedirect(
//           onProgressUpdate: (newProgress, {authCodeLoginUrl}) {
//             if (newProgress == MicrosoftAuthProgress.exchangingAuthCode) {
//               reachedExchangingAuthCodeProgress = true;
//             }
//           },
//         );

//         expect(reachedExchangingAuthCodeProgress, true);

//         // Passes auth code correctly to Microsoft API
//         verify(
//           () => _mockMicrosoftAuthApi.exchangeAuthCodeForTokens(fakeAuthCode),
//         ).called(1);
//       });

//       test(
//         'calls APIs correctly in order from Microsoft OAuth access token to Minecraft profile',
//         () async {
//           const microsoftOauthResponse = MicrosoftOauthTokenExchangeResponse(
//             accessToken: 'accessToken',
//             refreshToken: 'refreshToken2',
//             expiresIn: 7000,
//           );
//           const requestXboxLiveTokenResponse = XboxLiveAuthTokenResponse(
//             xboxToken: 'xboxToken',
//             userHash: 'userHash',
//           );
//           const requestXstsTokenResponse = XboxLiveAuthTokenResponse(
//             xboxToken: 'xboxToken2',
//             userHash: 'userHash2',
//           );
//           const minecraftLoginResponse = MinecraftLoginResponse(
//             username: 'dsadsadsa',
//             accessToken: 'dsadsadsadsasaddsadkspaoasdsadsad321312321',
//             expiresIn: -12,
//           );

//           const ownsMinecraftJava = true;

//           when(
//             () => _mockMicrosoftAuthApi.exchangeAuthCodeForTokens(any()),
//           ).thenAnswer((_) async => microsoftOauthResponse);
//           when(
//             () => _mockMicrosoftAuthApi.requestXboxLiveToken(any()),
//           ).thenAnswer((_) async => requestXboxLiveTokenResponse);
//           when(
//             () => _mockMicrosoftAuthApi.requestXSTSToken(any()),
//           ).thenAnswer((_) async => requestXstsTokenResponse);
//           when(
//             () => _mockMinecraftApi.loginToMinecraftWithXbox(any()),
//           ).thenAnswer((_) async => minecraftLoginResponse);
//           when(
//             () => _mockMinecraftApi.checkMinecraftJavaOwnership(any()),
//           ).thenAnswer((_) async => ownsMinecraftJava);

//           final progressEvents = <MicrosoftAuthProgress>[];

//           await simulateAuthCodeRedirect(
//             authCode: fakeAuthCode,
//             onProgressUpdate:
//                 (progress, {authCodeLoginUrl}) => progressEvents.add(progress),
//           );

//           expect(progressEvents, [
//             MicrosoftAuthProgress.waitingForUserLogin,
//             MicrosoftAuthProgress.exchangingAuthCode,
//             MicrosoftAuthProgress.requestingXboxToken,
//             MicrosoftAuthProgress.requestingXstsToken,
//             MicrosoftAuthProgress.loggingIntoMinecraft,
//             MicrosoftAuthProgress.checkingMinecraftJavaOwnership,
//             MicrosoftAuthProgress.fetchingProfile,
//           ]);
//           verifyInOrder([
//             () => _mockMicrosoftAuthApi.userLoginUrlWithAuthCode(),
//             () => _mockMicrosoftAuthApi.exchangeAuthCodeForTokens(fakeAuthCode),
//             () => _mockMicrosoftAuthApi.requestXboxLiveToken(
//               microsoftOauthResponse,
//             ),
//             () => _mockMicrosoftAuthApi.requestXSTSToken(
//               requestXboxLiveTokenResponse,
//             ),
//             () => _mockMinecraftApi.loginToMinecraftWithXbox(
//               requestXstsTokenResponse,
//             ),
//             () => _mockMinecraftApi.checkMinecraftJavaOwnership(
//               minecraftLoginResponse.accessToken,
//             ),
//             () => _mockMinecraftApi.fetchMinecraftProfile(
//               minecraftLoginResponse.accessToken,
//             ),
//           ]);
//           verifyNoMoreInteractions(_mockMicrosoftAuthApi);
//           verifyNoMoreInteractions(_mockMinecraftApi);
//         },
//       );

//       _minecraftAccountCreationFromApiResponsesTest((
//         microsoftOauthResponse,
//       ) async {
//         when(
//           () => _mockMicrosoftAuthApi.exchangeAuthCodeForTokens(any()),
//         ).thenAnswer((_) async => microsoftOauthResponse);
//         final (result, _) = await simulateAuthCodeRedirect();
//         return result;
//       });

//       _minecraftOwnershipTests(
//         performAuthAction: () async {
//           final (result, _) = await simulateAuthCodeRedirect();
//           return result;
//         },
//       );
//       _transformExceptionCommonTests(
//         () => _mockMinecraftApi,
//         () => _mockMicrosoftAuthApi,
//         () => simulateAuthCodeRedirect(),
//       );

//       _commonLoginMicrosoftTests(
//         performLoginAction: () async {
//           final (result, _) = await simulateAuthCodeRedirect();
//           return result;
//         },
//         mockMinecraftAccountCallback:
//             (newAccount) => mockLoginResult(
//               newAccount,
//               authAction: _TestAuthAction.loginWithAuthCode,
//             ),
//       );
//     });
//   });

//   group('device code flow', () {
//     test('deviceCodePollingTimer defaults to null', () {
//       expect(_minecraftAccountManager.deviceCodePollingTimer, null);
//     });

//     test('deviceCodePollingTimer the timer works correctly', () {
//       fakeAsync((async) {
//         bool callbackCalled = false;
//         int timerCallbackInvocationCount = 0;

//         const duration = Duration(seconds: 5);
//         _minecraftAccountManager.deviceCodePollingTimer = AsyncTimer.periodic(
//           const Duration(seconds: 5),
//           () {
//             callbackCalled = true;
//             timerCallbackInvocationCount++;
//           },
//         );

//         expect(callbackCalled, false);
//         expect(timerCallbackInvocationCount, 0);

//         async.elapse(duration);

//         expect(callbackCalled, true);
//         expect(timerCallbackInvocationCount, 1);

//         const additionalTicks = 500;
//         for (int i = 0; i < additionalTicks; i++) {
//           async.elapse(duration);
//         }

//         expect(timerCallbackInvocationCount, additionalTicks + 1);
//       });
//     });

//     test(
//       'isDeviceCodePollingTimerActive returns false when timer is not active',
//       () {
//         expect(_minecraftAccountManager.isDeviceCodePollingTimerActive, false);
//       },
//     );

//     AsyncTimer<MicrosoftDeviceCodeApproved?>
//     dummyTimer() => AsyncTimer.periodic(
//       // Dummy duration, this callback will not get invoked unless we call async.elapse().
//       const Duration(seconds: 5),
//       () => fail('Timer callback should not be called'),
//     );

//     test(
//       'isDeviceCodePollingTimerActive returns true when timer is active',
//       () {
//         fakeAsync((async) {
//           _minecraftAccountManager.deviceCodePollingTimer = dummyTimer();

//           expect(_minecraftAccountManager.isDeviceCodePollingTimerActive, true);
//           _minecraftAccountManager.cancelDeviceCodePollingTimer();

//           // Ensure cancellation
//           expect(
//             _minecraftAccountManager.isDeviceCodePollingTimerActive,
//             false,
//           );
//           expect(_minecraftAccountManager.deviceCodePollingTimer, null);
//         });
//       },
//     );

//     test('requestCancelDeviceCodePollingTimer defaults to false', () {
//       expect(
//         _minecraftAccountManager.requestCancelDeviceCodePollingTimer,
//         false,
//       );
//     });

//     test('cancelDeviceCodePollingTimer cancels the timer correctly', () {
//       fakeAsync((async) {
//         // Assuming false to confirm the timer sets it to true.
//         _minecraftAccountManager.requestCancelDeviceCodePollingTimer = false;

//         int timerCallbackInvocationCount = 0;
//         const duration = Duration(seconds: 5);
//         _minecraftAccountManager.deviceCodePollingTimer = AsyncTimer.periodic(
//           duration,
//           () => timerCallbackInvocationCount++,
//         );

//         // Ensure the timer is currently active
//         expect(_minecraftAccountManager.isDeviceCodePollingTimerActive, true);
//         expect(_minecraftAccountManager.deviceCodePollingTimer, isNotNull);

//         async.elapse(duration);
//         expect(
//           timerCallbackInvocationCount,
//           1,
//           reason: 'The timer is likely not working properly',
//         );

//         _minecraftAccountManager.cancelDeviceCodePollingTimer();

//         async.elapse(duration);
//         expect(
//           timerCallbackInvocationCount,
//           1,
//           reason:
//               'The timer has been cancelled but the callback is still invoking, likely a bug.',
//         );

//         expect(
//           _minecraftAccountManager.requestCancelDeviceCodePollingTimer,
//           true,
//           reason:
//               'Calling cancelDeviceCodePollingTimer should set requestCancelDeviceCodePollingTimer to false',
//         );
//         expect(_minecraftAccountManager.deviceCodePollingTimer, isNull);
//       });
//     });

//     Future<(AccountResult?, DeviceCodeTimerCloseReason)>
//     requestLoginWithMicrosoftDeviceCode({
//       OnAuthProgressUpdateCallback? onProgressUpdate,
//       OnDeviceCodeAvailableCallback? onDeviceCodeAvailable,
//     }) => _minecraftAccountManager.requestLoginWithMicrosoftDeviceCode(
//       onDeviceCodeAvailable: onDeviceCodeAvailable ?? (_) {},
//       onProgressUpdate: onProgressUpdate ?? (_) {},
//     );

//     group('requestLoginWithMicrosoftDeviceCode', () {
//       const int expiresInSeconds = 15 * 60; // 15 minutes
//       const int interval = 5; // 5 seconds

//       MicrosoftRequestDeviceCodeResponse requestCodeResponse({
//         String userCode = '',
//         int expiresIn = expiresInSeconds,
//         int interval = interval,
//       }) => MicrosoftRequestDeviceCodeResponse(
//         userCode: userCode,
//         deviceCode: '',
//         expiresIn: expiresIn,
//         interval: interval,
//       );

//       setUp(() {
//         when(() => _mockMicrosoftAuthApi.requestDeviceCode()).thenAnswer(
//           (_) async => requestCodeResponse(expiresIn: -1, interval: -1),
//         );
//         when(
//           () => _mockMicrosoftAuthApi.checkDeviceCodeStatus(any()),
//         ).thenAnswer(
//           (_) async =>
//               MicrosoftCheckDeviceCodeStatusResult.authorizationPending(),
//         );
//       });

//       setUpAll(() {
//         registerFallbackValue(
//           const MicrosoftRequestDeviceCodeResponse(
//             deviceCode: '',
//             expiresIn: -1,
//             interval: -1,
//             userCode: '',
//           ),
//         );
//       });
//       test('sets requestCancelDeviceCodePollingTimer to false', () {
//         _minecraftAccountManager.requestCancelDeviceCodePollingTimer = true;
//         requestLoginWithMicrosoftDeviceCode();
//         expect(
//           _minecraftAccountManager.requestCancelDeviceCodePollingTimer,
//           false,
//         );
//       });

//       Future<(AccountResult?, DeviceCodeTimerCloseReason)> simulateExpiration({
//         OnAuthProgressUpdateCallback? onProgressUpdate,
//         OnDeviceCodeAvailableCallback? onDeviceCodeAvailable,
//       }) {
//         final completer =
//             Completer<(AccountResult?, DeviceCodeTimerCloseReason)>();
//         fakeAsync((async) {
//           final future = requestLoginWithMicrosoftDeviceCode(
//             onDeviceCodeAvailable: onDeviceCodeAvailable,
//             onProgressUpdate: onProgressUpdate,
//           );

//           verify(() => _mockMicrosoftAuthApi.requestDeviceCode()).called(1);

//           // This will cause the timer to be cancelled the next time it triggers
//           when(
//             () => _mockMicrosoftAuthApi.checkDeviceCodeStatus(any()),
//           ).thenAnswer(
//             (_) async => MicrosoftCheckDeviceCodeStatusResult.expired(),
//           );

//           future
//               .then((result) {
//                 completer.complete(result);
//               })
//               .onError((e, stacktrace) {
//                 completer.completeError(e!, stacktrace);
//               });

//           // Trigger the timer callback
//           async.elapse(const Duration(seconds: interval + 1));

//           async.flushMicrotasks();
//         });

//         return completer.future.timeout(const Duration(seconds: 1));
//       }

//       Future<(AccountResult?, DeviceCodeTimerCloseReason)> simulateSuccess({
//         OnAuthProgressUpdateCallback? onProgressUpdate,
//         OnDeviceCodeAvailableCallback? onDeviceCodeAvailable,
//         MicrosoftOauthTokenExchangeResponse? mockCheckCodeResponse,
//         bool shouldMockCheckCodeResponse = true,
//         MicrosoftRequestDeviceCodeResponse? mockRequestCodeResponse,
//       }) {
//         when(() => _mockMicrosoftAuthApi.requestDeviceCode()).thenAnswer(
//           (_) async =>
//               mockRequestCodeResponse ??
//               const MicrosoftRequestDeviceCodeResponse(
//                 deviceCode: '',
//                 userCode: '',
//                 interval: interval,
//                 expiresIn: 5000,
//               ),
//         );

//         final completer =
//             Completer<(AccountResult?, DeviceCodeTimerCloseReason)>();
//         fakeAsync((async) {
//           final future = requestLoginWithMicrosoftDeviceCode(
//             onDeviceCodeAvailable: onDeviceCodeAvailable,
//             onProgressUpdate: onProgressUpdate,
//           );

//           if (shouldMockCheckCodeResponse) {
//             // This will cause the timer to be cancelled the next time it triggers
//             when(
//               () => _mockMicrosoftAuthApi.checkDeviceCodeStatus(any()),
//             ).thenAnswer(
//               (_) async => MicrosoftCheckDeviceCodeStatusResult.approved(
//                 mockCheckCodeResponse ??
//                     const MicrosoftOauthTokenExchangeResponse(
//                       accessToken: '',
//                       refreshToken: '',
//                       expiresIn: -1,
//                     ),
//               ),
//             );
//           }

//           future
//               .then((result) {
//                 completer.complete(result);
//               })
//               .onError((e, stacktrace) {
//                 completer.completeError(e!, stacktrace);
//               });

//           // Trigger the timer callback
//           async.elapse(const Duration(seconds: interval + 1));

//           async.flushMicrotasks();
//         });

//         return completer.future.timeout(const Duration(seconds: 1));
//       }

//       test('requests device code and provides the user code', () async {
//         const userDeviceCode = 'EXAMPLE-USER-CODE';
//         final requestDeviceCodeResponse = requestCodeResponse(
//           userCode: userDeviceCode,
//           expiresIn: expiresInSeconds,
//           interval: interval,
//         );

//         when(
//           () => _mockMicrosoftAuthApi.requestDeviceCode(),
//         ).thenAnswer((_) async => requestDeviceCodeResponse);

//         String? capturedUserDeviceCode;
//         final progressEvents = <MicrosoftAuthProgress>[];
//         await simulateExpiration(
//           onDeviceCodeAvailable:
//               (deviceCode) => capturedUserDeviceCode = deviceCode,
//           onProgressUpdate: (newProgress) => progressEvents.add(newProgress),
//         );

//         verify(
//           () => _mockMicrosoftAuthApi.checkDeviceCodeStatus(
//             requestDeviceCodeResponse,
//           ),
//         ).called(1);

//         verifyNoMoreInteractions(_mockMicrosoftAuthApi);
//         verifyZeroInteractions(_mockMinecraftApi);
//         verifyZeroInteractions(_mockAccountRepository);

//         expect(capturedUserDeviceCode, userDeviceCode);
//         expect(
//           progressEvents.first,
//           MicrosoftAuthProgress.waitingForUserLogin,
//           reason:
//               'onProgressUpdate should be called with ${MicrosoftAuthProgress.waitingForUserLogin.name} first. Progress list: $progressEvents',
//         );
//       });

//       test('uses correct interval duration and advances timer accordingly', () {
//         const fakeInterval = 50;
//         when(() => _mockMicrosoftAuthApi.requestDeviceCode()).thenAnswer(
//           (_) async => requestCodeResponse(
//             interval: fakeInterval,
//             // Set a high expiration (in seconds) to simulate long-lived polling without triggering expiration.
//             expiresIn: 5000000,
//           ),
//         );
//         when(
//           () => _mockMicrosoftAuthApi.checkDeviceCodeStatus(any()),
//         ).thenAnswer(
//           (_) async =>
//               MicrosoftCheckDeviceCodeStatusResult.authorizationPending(),
//         );

//         fakeAsync((async) {
//           requestLoginWithMicrosoftDeviceCode();

//           async.flushMicrotasks();

//           expect(
//             _minecraftAccountManager.deviceCodePollingTimer?.timer.tick,
//             0,
//           );

//           const duration = Duration(seconds: fakeInterval);

//           async.elapse(duration);

//           expect(
//             _minecraftAccountManager.deviceCodePollingTimer?.timer.tick,
//             1,
//           );

//           async.elapse(duration);

//           expect(
//             _minecraftAccountManager.deviceCodePollingTimer?.timer.tick,
//             2,
//           );

//           final currentTicks =
//               _minecraftAccountManager.deviceCodePollingTimer!.timer.tick;

//           const additionalTicks = 500;
//           for (int i = 0; i < additionalTicks; i++) {
//             async.elapse(duration);
//           }

//           expect(
//             _minecraftAccountManager.deviceCodePollingTimer!.timer.tick,
//             currentTicks + additionalTicks,
//           );

//           _minecraftAccountManager.cancelDeviceCodePollingTimer();
//         });
//       });

//       test(
//         'cancels timer on next run if cancellation was requested before timer initialization',
//         () {
//           // The timer can only be cancelled once it has been initialized. Before initialization,
//           // the device code is requested, which is an asynchronous call. During this time,
//           // users can cancel the operation, and the timer is null at this point.
//           // The requestCancelDeviceCodePollingTimer flag is used to cancel the timer
//           // the next time it is invoked, and it should be checked on each run.

//           // Example duration
//           const requestDeviceCodeDuration = Duration(seconds: interval * 2);

//           fakeAsync((async) {
//             when(() => _mockMicrosoftAuthApi.requestDeviceCode()).thenAnswer((
//               _,
//             ) async {
//               await Future<void>.delayed(requestDeviceCodeDuration);
//               return requestCodeResponse();
//             });

//             // Login with device code was requested.
//             final future = requestLoginWithMicrosoftDeviceCode();

//             // The requestDeviceCode call is still not finished yet after this call.
//             async.elapse(
//               requestDeviceCodeDuration - const Duration(seconds: 2),
//             );

//             verify(() => _mockMicrosoftAuthApi.requestDeviceCode()).called(1);

//             // Users might want to login with auth code instead before requestDeviceCode finishes,
//             // cancelling the device code polling.
//             _minecraftAccountManager.cancelDeviceCodePollingTimer();

//             expect(
//               _minecraftAccountManager.requestCancelDeviceCodePollingTimer,
//               true,
//               reason:
//                   'The requestCancelDeviceCodePollingTimer flag should be true when cancelDeviceCodePollingTimer is called',
//             );

//             async.elapse(requestDeviceCodeDuration);

//             expect(
//               _minecraftAccountManager.deviceCodePollingTimer,
//               null,
//               reason:
//                   'The timer should be cancelled and null when it was requested to be cancelled before it got initialized',
//             );

//             // Ensure the code execution stops (i.e., `return` is used) after the timer is closed.
//             try {
//               verifyNever(
//                 () => _mockMicrosoftAuthApi.checkDeviceCodeStatus(any()),
//               );
//             } on TestFailure catch (e) {
//               fail(
//                 'Expected no call to checkDeviceCodeStatus after the timer was canceled.\n'
//                 'This likely means execution continued past the cancel call — is `return;` used after cancelDeviceCodePollingTimer when requestCancelDeviceCodePollingTimer is true?\n'
//                 'Details: $e',
//               );
//             }

//             bool callbackCompleted = false;
//             future.then((result) {
//               expect(result.$1, null);
//               expect(
//                 result.$2,
//                 DeviceCodeTimerCloseReason.cancelledByUser,
//                 reason:
//                     'The close reason should be ${DeviceCodeTimerCloseReason.cancelledByUser.name} because it was cancelled due to user request.',
//               );
//               callbackCompleted = true;
//             });

//             async.flushMicrotasks();
//             expect(
//               callbackCompleted,
//               true,
//               reason: 'The then callback was not completed',
//             );
//           });
//         },
//       );

//       test(
//         'cancels the timer and stops execution when the device code is expired while polling',
//         () {
//           const expiresIn = 5400;
//           when(() => _mockMicrosoftAuthApi.requestDeviceCode()).thenAnswer(
//             (_) async =>
//                 requestCodeResponse(expiresIn: expiresIn, interval: interval),
//           );

//           when(
//             () => _mockMicrosoftAuthApi.checkDeviceCodeStatus(any()),
//           ).thenAnswer(
//             (_) async =>
//                 MicrosoftCheckDeviceCodeStatusResult.authorizationPending(),
//           );

//           fakeAsync((async) {
//             final future = requestLoginWithMicrosoftDeviceCode();

//             async.flushMicrotasks();
//             expect(
//               _minecraftAccountManager.deviceCodePollingTimer,
//               isNotNull,
//               reason: 'The timer should not be null when it started',
//             );

//             const intervalDuration = Duration(seconds: interval);
//             async.elapse(intervalDuration);

//             expect(
//               _minecraftAccountManager.deviceCodePollingTimer,
//               isNotNull,
//               reason:
//                   'The code is still not expired after first timer invocation',
//             );

//             // Number of check attempts in timer before it gets expired.
//             // The check has run only once at this point.
//             const totalCheckUntilExpired = expiresIn / interval;
//             const checksUntilExpired = totalCheckUntilExpired - 1;

//             const checksBeforeExpiration = checksUntilExpired - 1;
//             for (int i = 0; i < checksBeforeExpiration; i++) {
//               async.elapse(intervalDuration);
//             }

//             expect(
//               _minecraftAccountManager.deviceCodePollingTimer,
//               isNotNull,
//               reason:
//                   'The code is still not expired before the last timer invocation',
//             );

//             async.elapse(intervalDuration);

//             expect(
//               _minecraftAccountManager.deviceCodePollingTimer,
//               isNull,
//               reason:
//                   'The timer should be cancelled after $totalCheckUntilExpired invocations where each invocation runs every ${intervalDuration.inSeconds}s since code expires in ${expiresIn}s',
//             );

//             bool callbackCompleted = false;
//             future.then((result) {
//               expect(result.$1, null);
//               expect(
//                 result.$2,
//                 DeviceCodeTimerCloseReason.codeExpired,
//                 reason:
//                     'The close reason should be ${DeviceCodeTimerCloseReason.codeExpired.name} as it was cancelled due to expiration',
//               );
//               callbackCompleted = true;
//             });

//             async.flushMicrotasks();
//             expect(
//               callbackCompleted,
//               true,
//               reason: 'The then callback was not completed',
//             );
//           });
//         },
//       );

//       // It might be confusing, but currently both this test and
//       // the one above it are testing the same thing in slightly different ways.
//       // This test verifies whether the timer callback checks if the code is expired.
//       // The test above this verifies whether the "Future.then" callback was used
//       // to cancel the timer on expiration, which is outside of the timer callback.
//       // Since the "Future.then" callback is always called in both cases, this test
//       // will not fail if the callback doesn't check whether the code is expired.
//       // Fixing this would require changes to production code, but it's not an issue.
//       test(
//         'cancels the timer and stops execution when the device code is expired after awaiting for expiresIn',
//         () {
//           const expiresIn = 9200;
//           when(() => _mockMicrosoftAuthApi.requestDeviceCode()).thenAnswer(
//             (_) async =>
//                 requestCodeResponse(expiresIn: expiresIn, interval: interval),
//           );
//           when(
//             () => _mockMicrosoftAuthApi.checkDeviceCodeStatus(any()),
//           ).thenAnswer(
//             (_) async =>
//                 MicrosoftCheckDeviceCodeStatusResult.authorizationPending(),
//           );

//           fakeAsync((async) {
//             final future = requestLoginWithMicrosoftDeviceCode();

//             async.flushMicrotasks();
//             expect(_minecraftAccountManager.deviceCodePollingTimer, isNotNull);
//             async.elapse(const Duration(seconds: expiresIn));
//             async.elapse(const Duration(seconds: interval));
//             expect(_minecraftAccountManager.deviceCodePollingTimer, null);

//             bool callbackCompleted = false;
//             future.then((result) {
//               expect(result.$1, null);
//               expect(
//                 result.$2,
//                 DeviceCodeTimerCloseReason.codeExpired,
//                 reason:
//                     'The close reason should be ${DeviceCodeTimerCloseReason.codeExpired.name} as it was cancelled due to expiration',
//               );
//               callbackCompleted = true;
//             });

//             async.flushMicrotasks();
//             expect(
//               callbackCompleted,
//               true,
//               reason: 'The then callback was not completed',
//             );
//           });
//         },
//       );

//       test('cancels timer as expired when API responds with expired', () async {
//         when(
//           () => _mockMicrosoftAuthApi.checkDeviceCodeStatus(any()),
//         ).thenAnswer(
//           (_) async => MicrosoftCheckDeviceCodeStatusResult.expired(),
//         );

//         fakeAsync((async) {
//           final future = requestLoginWithMicrosoftDeviceCode();

//           async.flushMicrotasks();

//           async.elapse(const Duration(seconds: interval));

//           expect(_minecraftAccountManager.deviceCodePollingTimer, null);

//           bool callbackCompleted = false;
//           future.then((result) {
//             expect(result.$1, null);
//             expect(result.$2, DeviceCodeTimerCloseReason.codeExpired);
//             callbackCompleted = true;
//           });

//           async.flushMicrotasks();
//           expect(
//             callbackCompleted,
//             true,
//             reason: 'The then callback was not completed',
//           );
//         });
//       });

//       test('continues polling when API responds with pending', () {
//         final requestDeviceCodeResponse = requestCodeResponse(
//           expiresIn: 9000,
//           interval: interval,
//         );
//         when(
//           () => _mockMicrosoftAuthApi.requestDeviceCode(),
//         ).thenAnswer((_) async => requestDeviceCodeResponse);
//         when(
//           () => _mockMicrosoftAuthApi.checkDeviceCodeStatus(any()),
//         ).thenAnswer(
//           (_) async =>
//               MicrosoftCheckDeviceCodeStatusResult.authorizationPending(),
//         );

//         fakeAsync((async) {
//           requestLoginWithMicrosoftDeviceCode();

//           async.flushMicrotasks();

//           verify(() => _mockMicrosoftAuthApi.requestDeviceCode()).called(1);

//           expect(
//             _minecraftAccountManager.deviceCodePollingTimer?.timer.tick,
//             0,
//           );

//           const duration = Duration(seconds: interval);

//           for (int i = 1; i <= 50; i++) {
//             async.elapse(duration);
//             expect(
//               _minecraftAccountManager.deviceCodePollingTimer?.timer.tick,
//               i,
//             );
//             verify(
//               () => _mockMicrosoftAuthApi.checkDeviceCodeStatus(
//                 requestDeviceCodeResponse,
//               ),
//             ).called(1);
//           }

//           _minecraftAccountManager.cancelDeviceCodePollingTimer();

//           async.elapse(duration);
//           expect(
//             _minecraftAccountManager.deviceCodePollingTimer?.timer.tick,
//             null,
//           );
//           verifyNoMoreInteractions(_mockMicrosoftAuthApi);
//         });
//       });

//       test(
//         'cancels the timer as ${DeviceCodeTimerCloseReason.approved} when API responds with success',
//         () {
//           when(() => _mockMicrosoftAuthApi.requestDeviceCode()).thenAnswer(
//             (_) async =>
//                 requestCodeResponse(expiresIn: 9000, interval: interval),
//           );
//           when(
//             () => _mockMicrosoftAuthApi.checkDeviceCodeStatus(any()),
//           ).thenAnswer(
//             (_) async => MicrosoftCheckDeviceCodeStatusResult.approved(
//               const MicrosoftOauthTokenExchangeResponse(
//                 accessToken: '',
//                 refreshToken: '',
//                 expiresIn: -1,
//               ),
//             ),
//           );

//           fakeAsync((async) {
//             final future = requestLoginWithMicrosoftDeviceCode();

//             async.flushMicrotasks();
//             async.elapse(const Duration(seconds: interval));

//             bool callbackCompleted = false;
//             future.then((result) {
//               expect(result.$1, isNotNull);
//               expect(
//                 result.$2,
//                 DeviceCodeTimerCloseReason.approved,
//                 reason:
//                     'The close reason should be ${DeviceCodeTimerCloseReason.approved.name} because it was cancelled due to a successful login.',
//               );
//               callbackCompleted = true;
//             });

//             async.flushMicrotasks();
//             expect(
//               callbackCompleted,
//               true,
//               reason: 'The then callback was not completed',
//             );
//           });
//         },
//       );

//       test(
//         'returns close reason ${DeviceCodeTimerCloseReason.cancelledByUser} when user cancels the operation',
//         () async {
//           when(() => _mockMicrosoftAuthApi.requestDeviceCode()).thenAnswer(
//             (_) async => requestCodeResponse(
//               expiresIn: expiresInSeconds,
//               interval: interval,
//             ),
//           );

//           fakeAsync((async) {
//             final future = requestLoginWithMicrosoftDeviceCode();

//             async.flushMicrotasks();

//             async.elapse(const Duration(seconds: interval));

//             _minecraftAccountManager.cancelDeviceCodePollingTimer();

//             bool callbackCompleted = true;
//             future.then((result) {
//               expect(result.$1, null);
//               expect(
//                 result.$2,
//                 DeviceCodeTimerCloseReason.cancelledByUser,
//                 reason:
//                     'The close reason should be ${DeviceCodeTimerCloseReason.cancelledByUser.name} because it was cancelled due to user request.',
//               );
//               callbackCompleted = true;
//             });

//             async.flushMicrotasks();
//             expect(
//               callbackCompleted,
//               true,
//               reason: 'The then callback was not completed',
//             );
//           });
//         },
//       );

//       test(
//         'returns close reason ${DeviceCodeTimerCloseReason.declined} when user cancels the operation',
//         () async {
//           when(() => _mockMicrosoftAuthApi.requestDeviceCode()).thenAnswer(
//             (_) async => requestCodeResponse(
//               expiresIn: expiresInSeconds,
//               interval: interval,
//             ),
//           );
//           when(
//             () => _mockMicrosoftAuthApi.checkDeviceCodeStatus(any()),
//           ).thenAnswer(
//             (_) async => MicrosoftCheckDeviceCodeStatusResult.declined(),
//           );
//           fakeAsync((async) {
//             final future = requestLoginWithMicrosoftDeviceCode();

//             async.flushMicrotasks();

//             async.elapse(const Duration(seconds: interval));

//             _minecraftAccountManager.cancelDeviceCodePollingTimer();

//             bool callbackCompleted = true;
//             future.then((result) {
//               expect(result.$1, null);
//               expect(
//                 result.$2,
//                 DeviceCodeTimerCloseReason.declined,
//                 reason:
//                     'The close reason should be ${DeviceCodeTimerCloseReason.declined.name} because the user explicitly denied the authorization request, so the timer was cancelled as a result.',
//               );
//               callbackCompleted = true;
//             });

//             async.flushMicrotasks();
//             expect(
//               callbackCompleted,
//               true,
//               reason: 'The then callback was not completed',
//             );
//           });
//         },
//       );

//       test(
//         'calls APIs correctly in order from Microsoft OAuth access token to Minecraft profile',
//         () async {
//           const microsoftOauthResponse = MicrosoftOauthTokenExchangeResponse(
//             accessToken: 'access token',
//             refreshToken: 'refresh token',
//             expiresIn: 4200,
//           );
//           const requestXboxLiveTokenResponse = XboxLiveAuthTokenResponse(
//             xboxToken: 'xboxToken',
//             userHash: 'userHash',
//           );
//           const requestXstsTokenResponse = XboxLiveAuthTokenResponse(
//             xboxToken: 'xboxToken2',
//             userHash: 'userHash2',
//           );
//           const minecraftLoginResponse = MinecraftLoginResponse(
//             username: 'dsadsadsa',
//             accessToken: 'dsadsadsadsasaddsadkspaoasdsadsad321312321',
//             expiresIn: -12,
//           );
//           const requestDeviceCodeResponse = MicrosoftRequestDeviceCodeResponse(
//             deviceCode: 'dsadsa',
//             expiresIn: 5000,
//             interval: 5,
//             userCode: '',
//           );

//           const ownsMinecraftJava = true;

//           when(
//             () => _mockMicrosoftAuthApi.requestXboxLiveToken(any()),
//           ).thenAnswer((_) async => requestXboxLiveTokenResponse);
//           when(
//             () => _mockMicrosoftAuthApi.requestXSTSToken(any()),
//           ).thenAnswer((_) async => requestXstsTokenResponse);
//           when(
//             () => _mockMinecraftApi.loginToMinecraftWithXbox(any()),
//           ).thenAnswer((_) async => minecraftLoginResponse);
//           when(
//             () => _mockMinecraftApi.checkMinecraftJavaOwnership(any()),
//           ).thenAnswer((_) async => ownsMinecraftJava);

//           final progressEvents = <MicrosoftAuthProgress>[];

//           await simulateSuccess(
//             mockRequestCodeResponse: requestDeviceCodeResponse,
//             mockCheckCodeResponse: microsoftOauthResponse,
//             onProgressUpdate:
//                 (progress, {authCodeLoginUrl}) => progressEvents.add(progress),
//           );

//           expect(progressEvents, [
//             MicrosoftAuthProgress.waitingForUserLogin,
//             MicrosoftAuthProgress.exchangingDeviceCode,
//             MicrosoftAuthProgress.requestingXboxToken,
//             MicrosoftAuthProgress.requestingXstsToken,
//             MicrosoftAuthProgress.loggingIntoMinecraft,
//             MicrosoftAuthProgress.checkingMinecraftJavaOwnership,
//             MicrosoftAuthProgress.fetchingProfile,
//           ]);
//           verifyInOrder([
//             () => _mockMicrosoftAuthApi.requestDeviceCode(),
//             () => _mockMicrosoftAuthApi.checkDeviceCodeStatus(
//               requestDeviceCodeResponse,
//             ),
//             () => _mockMicrosoftAuthApi.requestXboxLiveToken(
//               microsoftOauthResponse,
//             ),
//             () => _mockMicrosoftAuthApi.requestXSTSToken(
//               requestXboxLiveTokenResponse,
//             ),
//             () => _mockMinecraftApi.loginToMinecraftWithXbox(
//               requestXstsTokenResponse,
//             ),
//             () => _mockMinecraftApi.checkMinecraftJavaOwnership(
//               minecraftLoginResponse.accessToken,
//             ),
//             () => _mockMinecraftApi.fetchMinecraftProfile(
//               minecraftLoginResponse.accessToken,
//             ),
//           ]);
//           verifyNoMoreInteractions(_mockMicrosoftAuthApi);
//           verifyNoMoreInteractions(_mockMinecraftApi);
//         },
//       );

//       _minecraftAccountCreationFromApiResponsesTest(
//         (microsoftOauthResponse) async {
//           final (result, _) = await simulateSuccess(
//             mockCheckCodeResponse: microsoftOauthResponse,
//           );
//           return result;
//         },
//         // This test depends on clock.now(), and the usage of fakeAsync() in simulateSuccess() affects clock.now(), pass the difference in here for compare date times correctly
//         elapsed: const Duration(seconds: interval),
//       );

//       _minecraftOwnershipTests(
//         performAuthAction: () async {
//           final (result, _) = await simulateSuccess();
//           return result;
//         },
//       );

//       _transformExceptionCommonTests(
//         () => _mockMinecraftApi,
//         () => _mockMicrosoftAuthApi,
//         () => simulateSuccess(),
//       );

//       _commonLoginMicrosoftTests(
//         performLoginAction: () async {
//           final (result, _) = await simulateSuccess(
//             shouldMockCheckCodeResponse: false,
//           );
//           return result;
//         },
//         mockMinecraftAccountCallback:
//             (newAccount) => mockLoginResult(
//               newAccount,
//               authAction: _TestAuthAction.loginWithDeviceCode,
//             ),
//       );
//     });
//   });

//   group('removeAccount', () {
//     // TODO: Missing tests after refactoring, most of the logic was moved to AccountRepository
//   });

//   group('loadAccounts', () {
//     test('delegates to account storage', () {
//       final accounts1 = MinecraftAccounts.empty();
//       when(() => _mockAccountStorage.loadAccounts()).thenReturn(accounts1);

//       expect(
//         _minecraftAccountManager.loadAccounts().toComparableJson(),
//         accounts1.toComparableJson(),
//       );

//       verify(() => _mockAccountStorage.loadAccounts()).called(1);

//       final accounts2 = createMinecraftAccounts(
//         list: [
//           createMinecraftAccount(
//             id: 'example-id',
//             username: 'Steve',
//             accountType: AccountType.offline,
//           ),
//         ],
//       );

//       when(() => _mockAccountStorage.loadAccounts()).thenReturn(accounts2);

//       expect(
//         _minecraftAccountManager.loadAccounts().toComparableJson(),
//         accounts2.toComparableJson(),
//       );

//       verify(() => _mockAccountStorage.loadAccounts()).called(1);
//       verifyNever(() => _mockAccountStorage.saveAccounts(any()));
//       verifyNoMoreInteractions(_mockAccountStorage);

//       verifyZeroInteractions(_mockMicrosoftAuthApi);
//       verifyZeroInteractions(_mockMinecraftApi);
//     });

//     test('throws $UnknownAccountManagerException on $Exception', () {
//       final exception = Exception('An example exception');
//       when(() => _mockAccountStorage.loadAccounts()).thenThrow(exception);

//       expect(
//         () => _minecraftAccountManager.loadAccounts(),
//         throwsA(
//           isA<UnknownAccountManagerException>().having(
//             (e) => e.message,
//             'message',
//             equals(exception.toString()),
//           ),
//         ),
//       );

//       verify(() => _mockAccountStorage.loadAccounts()).called(1);
//       verifyNoMoreInteractions(_mockAccountStorage);
//     });
//   });

//   test('updateDefaultAccount updates defaultAccountId correctly', () {
//     const currentDefaultAccountId = 'id2';
//     const newDefaultAccountId = 'id1';

//     final initialAccounts = createMinecraftAccounts(
//       list: [
//         createMinecraftAccount(id: newDefaultAccountId),
//         createMinecraftAccount(id: currentDefaultAccountId),
//       ],
//       defaultAccountId: currentDefaultAccountId,
//     );
//     when(() => _mockAccountStorage.loadAccounts()).thenReturn(initialAccounts);

//     final accounts = _minecraftAccountManager.updateDefaultAccount(
//       newDefaultAccountId: newDefaultAccountId,
//     );

//     expect(accounts.defaultAccountId, newDefaultAccountId);
//     expect(
//       accounts.toComparableJson(),
//       initialAccounts
//           .copyWith(defaultAccountId: const Wrapped.value(newDefaultAccountId))
//           .toComparableJson(),
//     );

//     verify(() => _mockAccountStorage.loadAccounts()).called(1);
//     verify(() => _mockAccountStorage.saveAccounts(accounts)).called(1);
//     verifyNoMoreInteractions(_mockAccountStorage);

//     verifyZeroInteractions(_mockMicrosoftAuthApi);
//     verifyZeroInteractions(_mockMinecraftApi);
//   });

//   group('createOfflineAccount', () {
//     test('creates the account details correctly', () async {
//       const username = 'example_username';
//       final result = await _minecraftAccountManager.createOfflineAccount(
//         username: username,
//       );
//       final newAccount = result.newAccount;
//       expect(newAccount.accountType, AccountType.offline);
//       expect(newAccount.isMicrosoft, false);
//       expect(newAccount.username, username);
//       expect(newAccount.ownsMinecraftJava, null);
//       expect(
//         newAccount.skins,
//         <MinecraftSkin>[],
//         reason: 'Skins are not supported on offline accounts',
//       );
//       expect(
//         newAccount.capes,
//         <MinecraftCape>[],
//         reason: 'Capes are not supported on offline accounts',
//       );

//       final uuidV4Regex = RegExp(
//         r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
//       );
//       expect(newAccount.id, matches(uuidV4Regex));

//       expect(result.hasUpdatedExistingAccount, false);
//     });

//     test('saves and adds the account to the list when there are no accounts', () {
//       when(
//         () => _mockAccountStorage.loadAccounts(),
//       ).thenReturn(MinecraftAccounts.empty());

//       final result = _minecraftAccountManager.createOfflineAccount(
//         username: '',
//       );
//       final newAccount = result.newAccount;

//       expect(
//         result.updatedAccounts.defaultAccountId,
//         newAccount.id,
//         reason:
//             'The defaultAccountId should be set to the newly created account when there are no accounts.',
//       );
//       expect(
//         result.updatedAccounts.toComparableJson(),
//         MinecraftAccounts(
//           list: [newAccount],
//           defaultAccountId: newAccount.id,
//         ).toComparableJson(),
//       );
//       expect(result.updatedAccounts.list.length, 1);

//       verifyInOrder([
//         () => _mockAccountStorage.loadAccounts(),
//         () => _mockAccountStorage.saveAccounts(result.updatedAccounts),
//       ]);
//       verifyNoMoreInteractions(_mockAccountStorage);

//       verifyZeroInteractions(_mockMicrosoftAuthApi);
//       verifyZeroInteractions(_mockMinecraftApi);
//     });

//     test('saves and adds the account to the list when there are accounts', () {
//       final currentDefaultAccountId =
//           MinecraftDummyAccounts.accounts.defaultAccountId;

//       final existingAccounts = MinecraftDummyAccounts.accounts;
//       when(
//         () => _mockAccountStorage.loadAccounts(),
//       ).thenReturn(existingAccounts);

//       final result = _minecraftAccountManager.createOfflineAccount(
//         username: '',
//       );
//       final newAccount = result.newAccount;

//       expect(
//         result.updatedAccounts.defaultAccountId,
//         currentDefaultAccountId,
//         reason:
//             'Should keep defaultAccountId unchanged when there is already an existing default account.',
//       );
//       expect(
//         result.updatedAccounts.toComparableJson(),
//         MinecraftAccounts(
//           list: [newAccount, ...existingAccounts.list],
//           defaultAccountId: currentDefaultAccountId,
//         ).toComparableJson(),
//       );
//       expect(
//         result.updatedAccounts.list.length,
//         existingAccounts.list.length + 1,
//       );

//       verifyInOrder([
//         () => _mockAccountStorage.loadAccounts(),
//         () => _mockAccountStorage.saveAccounts(result.updatedAccounts),
//       ]);
//       verifyNoMoreInteractions(_mockAccountStorage);

//       verifyZeroInteractions(_mockMicrosoftAuthApi);
//       verifyZeroInteractions(_mockMinecraftApi);
//     });

//     test('creates unique id', () async {
//       final id1 =
//           (await _minecraftAccountManager.createOfflineAccount(
//             username: '',
//           )).newAccount.id;
//       final id2 =
//           (await _minecraftAccountManager.createOfflineAccount(
//             username: '',
//           )).newAccount.id;
//       final id3 =
//           (await _minecraftAccountManager.createOfflineAccount(
//             username: '',
//           )).newAccount.id;
//       expect(id1, isNot(equals(id2)));
//       expect(id2, isNot(equals(id3)));
//       expect(id3, isNot(equals(id1)));
//     });
//   });

//   test('updateOfflineAccount updates the account correctly', () {
//     final initialAccounts = MinecraftDummyAccounts.accounts;
//     final originalAccount = initialAccounts.list.firstWhere(
//       (account) => account.accountType == AccountType.offline,
//     );

//     when(() => _mockAccountStorage.loadAccounts()).thenReturn(initialAccounts);

//     const newUsername = 'new_player_username4';
//     final result = _minecraftAccountManager.updateOfflineAccount(
//       accountId: originalAccount.id,
//       username: newUsername,
//     );
//     final updatedAccount = result.newAccount;

//     expect(
//       updatedAccount.id,
//       originalAccount.id,
//       reason: 'The account ID should remain unchanged.',
//     );
//     expect(updatedAccount.accountType, AccountType.offline);
//     expect(updatedAccount.isMicrosoft, false);
//     expect(updatedAccount.microsoftAccountInfo, null);
//     expect(updatedAccount.username, newUsername);
//     expect(updatedAccount.skins, isEmpty);
//     expect(
//       updatedAccount.toComparableJson(),
//       originalAccount.copyWith(username: newUsername).toComparableJson(),
//     );
//     expect(
//       result.updatedAccounts.defaultAccountId,
//       initialAccounts.defaultAccountId,
//     );

//     final originalAccountIndex = initialAccounts.list.indexWhere(
//       (account) => account.id == originalAccount.id,
//     );

//     expect(
//       result.updatedAccounts.toComparableJson(),
//       initialAccounts
//           .copyWith(
//             list: List<MinecraftAccount>.from(initialAccounts.list)
//               ..[originalAccountIndex] = updatedAccount,
//           )
//           .toComparableJson(),
//     );
//     expect(result.hasUpdatedExistingAccount, true);

//     verifyInOrder([
//       () => _mockAccountStorage.loadAccounts(),
//       () => _mockAccountStorage.saveAccounts(result.updatedAccounts),
//     ]);
//     verifyNoMoreInteractions(_mockAccountStorage);

//     verifyZeroInteractions(_mockMinecraftApi);
//     verifyZeroInteractions(_mockMicrosoftAuthApi);
//   });

//   group('refreshMicrosoftAccount', () {
//     setUp(() {
//       when(
//         () => _mockMicrosoftAuthApi.getNewTokensFromRefreshToken(any()),
//       ).thenAnswer(
//         (_) async => const MicrosoftOauthTokenExchangeResponse(
//           accessToken: '',
//           expiresIn: -1,
//           refreshToken: '',
//         ),
//       );
//       when(
//         () => _mockImageCacheService.evictFromCache(any()),
//       ).thenAnswer((_) async => true);
//     });

//     Future<(AccountResult refreshResult, MinecraftAccount existingAccount)>
//     refreshAccount({
//       MinecraftAccount? accountBeforeRefresh,
//       OnAuthProgressUpdateCallback? onProgressUpdate,
//     }) async {
//       final existingAccount =
//           accountBeforeRefresh ??
//           createMinecraftAccount(
//             accountType: AccountType.microsoft,
//             microsoftAccountInfo: createMicrosoftAccountInfo(),
//           );
//       final refreshResult = await _minecraftAccountManager
//           .refreshMicrosoftAccount(
//             existingAccount,
//             onProgressUpdate: onProgressUpdate ?? (_) {},
//           );
//       return (refreshResult, existingAccount);
//     }

//     test('throws $ArgumentError when $MicrosoftAccountInfo is null', () async {
//       await expectLater(
//         refreshAccount(
//           accountBeforeRefresh: createMinecraftAccount(
//             isMicrosoftAccountInfoNull: true,
//           ),
//         ),
//         throwsArgumentError,
//       );
//     });

//     _testRefreshAccountWithExpiredOrRevokedMicrosoftAccount(
//       (account) => refreshAccount(accountBeforeRefresh: account),
//     );

//     test('updates progress and passes refresh token correctly', () async {
//       final progressEvents = <MicrosoftAuthProgress>[];

//       final refreshToken = ExpirableToken(value: '', expiresAt: DateTime(2030));
//       await refreshAccount(
//         onProgressUpdate: (newProgress) => progressEvents.add(newProgress),
//         accountBeforeRefresh: createMinecraftAccount(
//           microsoftAccountInfo: createMicrosoftAccountInfo(
//             microsoftOAuthRefreshToken: refreshToken,
//           ),
//         ),
//       );

//       expect(
//         progressEvents.first,
//         MicrosoftAuthProgress.refreshingMicrosoftTokens,
//         reason:
//             'onProgressUpdate should be called with ${MicrosoftAuthProgress.refreshingMicrosoftTokens.name} first. Progress list: $progressEvents',
//       );
//       final verificationResult = verify(
//         () => _mockMicrosoftAuthApi.getNewTokensFromRefreshToken(captureAny()),
//       );
//       verificationResult.called(1);
//       final capturedRefreshToken = verificationResult.captured.first as String?;

//       expect(capturedRefreshToken, refreshToken.value);
//     });

//     test('deletes current cached skin images', () async {
//       const exampleUserId = 'Example Minecraft ID';
//       final (result, existingAccount) = await refreshAccount(
//         accountBeforeRefresh: createMinecraftAccount(
//           id: exampleUserId,
//           microsoftAccountInfo: createMicrosoftAccountInfo(
//             microsoftOAuthRefreshToken: createExpirableToken(),
//           ),
//         ),
//       );
//       verify(
//         () => _mockImageCacheService.evictFromCache(
//           existingAccount.fullSkinImageUrl,
//         ),
//       ).called(1);
//       verify(
//         () => _mockImageCacheService.evictFromCache(
//           existingAccount.headSkinImageUrl,
//         ),
//       ).called(1);
//     });

//     test(
//       'calls APIs correctly in order from Microsoft OAuth refresh token to Minecraft profile',
//       () async {
//         const microsoftOauthResponse = MicrosoftOauthTokenExchangeResponse(
//           accessToken: 'accessToken22',
//           refreshToken: 'rexsxfreshToken2',
//           expiresIn: 3200,
//         );
//         const requestXboxLiveTokenResponse = XboxLiveAuthTokenResponse(
//           xboxToken: 'xboxToken',
//           userHash: 'userHash',
//         );
//         const requestXstsTokenResponse = XboxLiveAuthTokenResponse(
//           xboxToken: 'xboxToken2',
//           userHash: 'userHash2',
//         );
//         const minecraftLoginResponse = MinecraftLoginResponse(
//           username: 'dsadsadsa',
//           accessToken: 'dsadsadsadsasaddsadkspaoasdsadsad321312321',
//           expiresIn: -12,
//         );

//         const ownsMinecraftJava = true;

//         when(
//           () => _mockMicrosoftAuthApi.getNewTokensFromRefreshToken(any()),
//         ).thenAnswer((_) async => microsoftOauthResponse);
//         when(
//           () => _mockMicrosoftAuthApi.requestXboxLiveToken(any()),
//         ).thenAnswer((_) async => requestXboxLiveTokenResponse);
//         when(
//           () => _mockMicrosoftAuthApi.requestXSTSToken(any()),
//         ).thenAnswer((_) async => requestXstsTokenResponse);
//         when(
//           () => _mockMinecraftApi.loginToMinecraftWithXbox(any()),
//         ).thenAnswer((_) async => minecraftLoginResponse);
//         when(
//           () => _mockMinecraftApi.checkMinecraftJavaOwnership(any()),
//         ).thenAnswer((_) async => ownsMinecraftJava);

//         final progressEvents = <MicrosoftAuthProgress>[];

//         final inputRefreshToken = ExpirableToken(
//           value: 'example-microsoft-refresh-token',
//           // Avoid refresh token expiration
//           expiresAt: clock.now().add(
//             const Duration(days: MicrosoftConstants.refreshTokenExpiresInDays),
//           ),
//         );
//         await refreshAccount(
//           onProgressUpdate:
//               (progress, {authCodeLoginUrl}) => progressEvents.add(progress),
//           accountBeforeRefresh: createMinecraftAccount(
//             microsoftAccountInfo: createMicrosoftAccountInfo(
//               microsoftOAuthRefreshToken: inputRefreshToken,
//             ),
//           ),
//         );

//         expect(progressEvents, [
//           MicrosoftAuthProgress.refreshingMicrosoftTokens,
//           MicrosoftAuthProgress.requestingXboxToken,
//           MicrosoftAuthProgress.requestingXstsToken,
//           MicrosoftAuthProgress.loggingIntoMinecraft,
//           MicrosoftAuthProgress.checkingMinecraftJavaOwnership,
//           MicrosoftAuthProgress.fetchingProfile,
//         ]);
//         verifyInOrder([
//           () => _mockMicrosoftAuthApi.getNewTokensFromRefreshToken(
//             inputRefreshToken.value,
//           ),
//           () => _mockMicrosoftAuthApi.requestXboxLiveToken(
//             microsoftOauthResponse,
//           ),
//           () => _mockMicrosoftAuthApi.requestXSTSToken(
//             requestXboxLiveTokenResponse,
//           ),
//           () => _mockMinecraftApi.loginToMinecraftWithXbox(
//             requestXstsTokenResponse,
//           ),
//           () => _mockMinecraftApi.checkMinecraftJavaOwnership(
//             minecraftLoginResponse.accessToken,
//           ),
//           () => _mockMinecraftApi.fetchMinecraftProfile(
//             minecraftLoginResponse.accessToken,
//           ),
//         ]);
//         verifyNoMoreInteractions(_mockMicrosoftAuthApi);
//         verifyNoMoreInteractions(_mockMinecraftApi);
//       },
//     );

//     _minecraftAccountCreationFromApiResponsesTest((
//       microsoftOauthResponse,
//     ) async {
//       when(
//         () => _mockMicrosoftAuthApi.getNewTokensFromRefreshToken(any()),
//       ).thenAnswer((_) async => microsoftOauthResponse);
//       final (result, _) = await refreshAccount();
//       return result;
//     });

//     _minecraftOwnershipTests(
//       performAuthAction: () async {
//         final (result, _) = await refreshAccount();
//         return result;
//       },
//     );

//     _transformExceptionCommonTests(
//       () => _mockMinecraftApi,
//       () => _mockMicrosoftAuthApi,
//       () => refreshAccount(),
//     );

//     test(
//       'saves and returns the refreshed account correctly without modifying other accounts',
//       () async {
//         const refreshAccountId = 'player-id';

//         final accountBeforeRefresh = MinecraftDummyAccount.account.copyWith(
//           id: refreshAccountId,
//           accountType: AccountType.microsoft,
//           microsoftAccountInfo: MinecraftDummyAccount
//               .account
//               .microsoftAccountInfo!
//               .copyWith(needsReAuthentication: false),
//         );
//         const currentDefaultAccountId = 'current-default-account-id';
//         final existingAccounts = createMinecraftAccounts(
//           list: [
//             createMinecraftAccount(
//               id: currentDefaultAccountId,
//               username: 'player_username2',
//               accountType: AccountType.offline,
//             ),
//             createMinecraftAccount(
//               id: 'account-id3',
//               username: 'player_username3',
//               accountType: AccountType.offline,
//             ),
//             accountBeforeRefresh,
//           ],
//           defaultAccountId: currentDefaultAccountId,
//         );

//         when(
//           () => _mockAccountStorage.loadAccounts(),
//         ).thenReturn(existingAccounts);

//         final expectedRefreshedAccount = accountBeforeRefresh.copyWith(
//           username: 'new_player_username_after_refresh',
//           skins: [
//             const MinecraftSkin(
//               id: 'refreshed-skin',
//               state: MinecraftCosmeticState.active,
//               url: 'http://dasdsasdsadsa',
//               textureKey: 'dasdsadsadsadsadsa',
//               variant: MinecraftSkinVariant.slim,
//             ),
//           ],
//           microsoftAccountInfo: MicrosoftAccountInfo(
//             microsoftOAuthAccessToken: ExpirableToken(
//               value: 'microsoft-access-token-after-refresh',
//               expiresAt: DateTime(2029, 3, 21, 12, 43),
//             ),
//             microsoftOAuthRefreshToken: ExpirableToken(
//               value: 'microsoft-refresh-token-after-refresh',
//               expiresAt: DateTime(2014),
//             ),
//             minecraftAccessToken: ExpirableToken(
//               value: 'minecraft-access-token-after-refresh',
//               expiresAt: DateTime(2027, 2, 27, 12, 30),
//             ),
//             needsReAuthentication: false,
//           ),
//         );
//         mockLoginResult(
//           expectedRefreshedAccount,
//           authAction: _TestAuthAction.refreshAccount,
//         );

//         final ((result), _) = await refreshAccount(
//           accountBeforeRefresh: accountBeforeRefresh,
//         );
//         final updatedAccounts = result.updatedAccounts;
//         final refreshedAccount = result.newAccount;

//         expect(
//           updatedAccounts.defaultAccountId,
//           existingAccounts.defaultAccountId,
//           reason:
//               'The defaultAccountId should remain untouched when refreshing an account.',
//         );
//         expect(
//           refreshedAccount.accountType,
//           AccountType.microsoft,
//           reason:
//               'The accountType should remain ${AccountType.microsoft.name} when refreshing a Microsoft account.',
//         );
//         expect(
//           refreshedAccount.id,
//           accountBeforeRefresh.id,
//           reason:
//               'The account id should remain the same when refreshing a Microsoft account.',
//         );
//         expect(
//           refreshedAccount.toComparableJson(),
//           expectedRefreshedAccount.toComparableJson(),
//         );
//         expect(
//           result.updatedAccounts.list.length,
//           existingAccounts.list.length,
//           reason: 'Refreshing an account should not add or remove accounts.',
//         );

//         expect(
//           result.updatedAccounts.toComparableJson(),
//           existingAccounts
//               .copyWith(
//                 list: result.updatedAccounts.list.updateById(
//                   refreshAccountId,
//                   (_) => expectedRefreshedAccount,
//                 ),
//               )
//               .toComparableJson(),
//         );

//         verify(() => _mockAccountStorage.loadAccounts()).called(1);
//         verify(
//           () => _mockAccountStorage.saveAccounts(result.updatedAccounts),
//         ).called(1);
//         verifyNoMoreInteractions(_mockAccountStorage);
//       },
//     );

//     test(
//       'sets needsReAuthentication to true for the account on $ExpiredOrUnauthorizedRefreshTokenMicrosoftAuthException and throws $MicrosoftExpiredOrUnauthorizedRefreshTokenAccountManagerException',
//       () async {
//         const refreshAccountId = 'id';

//         final accountBeforeRefresh = MinecraftDummyAccount.account.copyWith(
//           id: refreshAccountId,
//           microsoftAccountInfo: MinecraftDummyAccount
//               .account
//               .microsoftAccountInfo!
//               .copyWith(needsReAuthentication: false),
//         );

//         final existingAccounts = MinecraftDummyAccounts.accounts.copyWith(
//           list: [accountBeforeRefresh, ...MinecraftDummyAccounts.accounts.list],
//         );

//         when(
//           () => _mockAccountStorage.loadAccounts(),
//         ).thenAnswer((_) => existingAccounts);
//         when(
//           () => _mockMicrosoftAuthApi.getNewTokensFromRefreshToken(any()),
//         ).thenAnswer(
//           (_) async =>
//               throw MicrosoftAuthException.expiredOrUnauthorizedMicrosoftRefreshToken(),
//         );

//         await expectLater(
//           _minecraftAccountManager.refreshMicrosoftAccount(
//             accountBeforeRefresh,
//             onProgressUpdate: (_) {},
//           ),
//           throwsA(
//             isA<
//                   MicrosoftExpiredOrUnauthorizedRefreshTokenAccountManagerException
//                 >()
//                 .having(
//                   (e) => e.updatedAccount.toJson(),
//                   'updatedAccount',
//                   accountBeforeRefresh
//                       .copyWith(
//                         microsoftAccountInfo: accountBeforeRefresh
//                             .microsoftAccountInfo!
//                             .copyWith(needsReAuthentication: true),
//                       )
//                       .toJson(),
//                 ),
//           ),
//         );

//         final expectedAccountsReAuthUpdated = existingAccounts.updateById(
//           refreshAccountId,
//           (account) => account.copyWith(
//             microsoftAccountInfo: account.microsoftAccountInfo!.copyWith(
//               needsReAuthentication: true,
//             ),
//           ),
//         );

//         verify(() => _mockAccountStorage.loadAccounts()).called(1);

//         final result = verify(
//           () => _mockAccountStorage.saveAccounts(captureAny()),
//         );
//         result.called(1);

//         final capturedAccountsReAuthUpdated =
//             result.captured.first as MinecraftAccounts;
//         expect(
//           capturedAccountsReAuthUpdated.toJson(),
//           expectedAccountsReAuthUpdated.toJson(),
//         );
//         verifyNoMoreInteractions(_mockAccountStorage);

//         verifyZeroInteractions(_mockMinecraftApi);
//       },
//     );
//   });

//   group('refreshMinecraftAccessTokenIfExpired', () {
//     Future<MinecraftAccount> refreshMinecraftAccessTokenIfExpired(
//       MinecraftAccount account, {
//       OnAuthProgressUpdateCallback? onRefreshProgressUpdate,
//     }) => _minecraftAccountManager.refreshMinecraftAccessTokenIfExpired(
//       account,
//       onRefreshProgressUpdate: onRefreshProgressUpdate ?? (_) {},
//     );
//     Future<MinecraftAccount> refreshWithExpiredMinecraftAccessToken(
//       MinecraftAccount account, {
//       OnAuthProgressUpdateCallback? onRefreshProgressUpdate,
//       DateTime? fixedDateTime,
//     }) {
//       final clockTime = fixedDateTime ?? DateTime(2025, 5, 23, 10, 16);

//       final expiredAccount = account.copyWith(
//         microsoftAccountInfo: account.microsoftAccountInfo!.copyWith(
//           minecraftAccessToken: account
//               .microsoftAccountInfo!
//               .minecraftAccessToken
//               .copyWith(
//                 // Simulate expiration
//                 expiresAt: clockTime.subtract(const Duration(days: 1)),
//               ),
//         ),
//       );

//       return withClock(Clock.fixed(clockTime), () {
//         return _minecraftAccountManager.refreshMinecraftAccessTokenIfExpired(
//           expiredAccount,
//           onRefreshProgressUpdate: onRefreshProgressUpdate ?? (_) {},
//         );
//       });
//     }

//     test('throws $ArgumentError when $MicrosoftAccountInfo is null', () async {
//       await expectLater(
//         refreshMinecraftAccessTokenIfExpired(
//           createMinecraftAccount(accountType: AccountType.offline),
//         ),
//         throwsArgumentError,
//       );
//     });

//     group('when Minecraft access token is expired', () {
//       _testRefreshAccountWithExpiredOrRevokedMicrosoftAccount(
//         (account) => refreshWithExpiredMinecraftAccessToken(account),
//       );

//       test(
//         'calls APIs correctly in order from Microsoft OAuth refresh token to Minecraft access token',
//         () async {
//           const microsoftOauthResponse = MicrosoftOauthTokenExchangeResponse(
//             accessToken: 'example-access-token',
//             refreshToken: 'example-refresh-token',
//             expiresIn: 4500,
//           );
//           const requestXboxLiveTokenResponse = XboxLiveAuthTokenResponse(
//             xboxToken: 'example-token',
//             userHash: 'example-user-hash',
//           );
//           const requestXstsTokenResponse = XboxLiveAuthTokenResponse(
//             xboxToken: 'example-xsts-token',
//             userHash: 'example-xsts-user-hash',
//           );
//           const minecraftLoginResponse = MinecraftLoginResponse(
//             username: '7b1ff0da-a75b-507f-5c39-7262la7dl1f2',
//             accessToken: 'example-access-token',
//             expiresIn: -1,
//           );

//           when(
//             () => _mockMicrosoftAuthApi.getNewTokensFromRefreshToken(any()),
//           ).thenAnswer((_) async => microsoftOauthResponse);
//           when(
//             () => _mockMicrosoftAuthApi.requestXboxLiveToken(any()),
//           ).thenAnswer((_) async => requestXboxLiveTokenResponse);
//           when(
//             () => _mockMicrosoftAuthApi.requestXSTSToken(any()),
//           ).thenAnswer((_) async => requestXstsTokenResponse);
//           when(
//             () => _mockMinecraftApi.loginToMinecraftWithXbox(any()),
//           ).thenAnswer((_) async => minecraftLoginResponse);

//           final progressEvents = <MicrosoftAuthProgress>[];

//           final account = createMinecraftAccount();

//           await refreshWithExpiredMinecraftAccessToken(
//             account,
//             onRefreshProgressUpdate:
//                 (newProgress) => progressEvents.add(newProgress),
//           );

//           expect(progressEvents, [
//             MicrosoftAuthProgress.refreshingMicrosoftTokens,
//             MicrosoftAuthProgress.requestingXboxToken,
//             MicrosoftAuthProgress.requestingXstsToken,
//             MicrosoftAuthProgress.loggingIntoMinecraft,
//           ]);
//           verifyInOrder([
//             () => _mockMicrosoftAuthApi.getNewTokensFromRefreshToken(
//               account.microsoftAccountInfo!.microsoftOAuthRefreshToken.value,
//             ),
//             () => _mockMicrosoftAuthApi.requestXboxLiveToken(
//               microsoftOauthResponse,
//             ),
//             () => _mockMicrosoftAuthApi.requestXSTSToken(
//               requestXboxLiveTokenResponse,
//             ),
//             () => _mockMinecraftApi.loginToMinecraftWithXbox(
//               requestXstsTokenResponse,
//             ),
//           ]);

//           verifyNoMoreInteractions(_mockMicrosoftAuthApi);
//           verifyNoMoreInteractions(_mockMinecraftApi);
//         },
//       );

//       test('returns a new account instance with updated tokens', () async {
//         const microsoftOauthResponse = MicrosoftOauthTokenExchangeResponse(
//           accessToken: 'example-access-token',
//           refreshToken: 'example-refresh-token',
//           expiresIn: 4500,
//         );

//         const minecraftLoginResponse = MinecraftLoginResponse(
//           username: '7b1ff0da-a75b-507f-5c39-7262la7dl1f2',
//           accessToken: 'example-minecraft-access-token',
//           expiresIn: 9600,
//         );

//         when(
//           () => _mockMicrosoftAuthApi.getNewTokensFromRefreshToken(any()),
//         ).thenAnswer((_) async => microsoftOauthResponse);
//         when(
//           () => _mockMicrosoftAuthApi.requestXboxLiveToken(any()),
//         ).thenAnswer(
//           (_) async => const XboxLiveAuthTokenResponse(
//             xboxToken: 'example-token',
//             userHash: 'example-user-hash',
//           ),
//         );
//         when(() => _mockMicrosoftAuthApi.requestXSTSToken(any())).thenAnswer(
//           (_) async => const XboxLiveAuthTokenResponse(
//             xboxToken: 'example-xsts-token',
//             userHash: 'example-xsts-user-hash',
//           ),
//         );
//         when(
//           () => _mockMinecraftApi.loginToMinecraftWithXbox(any()),
//         ).thenAnswer((_) async => minecraftLoginResponse);

//         final expiredAccount = MinecraftDummyAccount.account;
//         final fixedDateTime = DateTime(2030, 10, 5, 10);
//         final refreshedAccount = await refreshWithExpiredMinecraftAccessToken(
//           expiredAccount,
//           fixedDateTime: fixedDateTime,
//         );
//         expect(refreshedAccount, isNot(same(expiredAccount)));

//         final expectedMicrosoftRefreshTokenExpiresAt = fixedDateTime.add(
//           const Duration(days: MicrosoftConstants.refreshTokenExpiresInDays),
//         );
//         final expectedMicrosoftAccessTokenExpiresAt = fixedDateTime.add(
//           Duration(seconds: minecraftLoginResponse.expiresIn),
//         );
//         final expectedMinecraftAccessTokenExpiresAt = fixedDateTime.add(
//           Duration(seconds: minecraftLoginResponse.expiresIn),
//         );
//         expect(
//           refreshedAccount
//               .microsoftAccountInfo
//               ?.microsoftOAuthRefreshToken
//               .expiresAt,
//           expectedMicrosoftRefreshTokenExpiresAt,
//         );
//         expect(
//           refreshedAccount
//               .microsoftAccountInfo
//               ?.microsoftOAuthAccessToken
//               .expiresAt,
//           expectedMicrosoftAccessTokenExpiresAt,
//         );
//         expect(
//           refreshedAccount.microsoftAccountInfo?.minecraftAccessToken.expiresAt,
//           expectedMinecraftAccessTokenExpiresAt,
//         );

//         final expiredMicrosoftAccountInfo =
//             expiredAccount.microsoftAccountInfo!;

//         expect(
//           refreshedAccount.toJson(),
//           expiredAccount
//               .copyWith(
//                 microsoftAccountInfo: expiredMicrosoftAccountInfo.copyWith(
//                   microsoftOAuthRefreshToken: expiredMicrosoftAccountInfo
//                       .microsoftOAuthRefreshToken
//                       .copyWith(
//                         expiresAt: expectedMicrosoftRefreshTokenExpiresAt,
//                         value: microsoftOauthResponse.refreshToken,
//                       ),
//                   microsoftOAuthAccessToken: expiredMicrosoftAccountInfo
//                       .microsoftOAuthRefreshToken
//                       .copyWith(
//                         expiresAt: expectedMicrosoftAccessTokenExpiresAt,
//                         value: microsoftOauthResponse.accessToken,
//                       ),
//                   minecraftAccessToken: expiredMicrosoftAccountInfo
//                       .minecraftAccessToken
//                       .copyWith(
//                         expiresAt: expectedMinecraftAccessTokenExpiresAt,
//                         value: minecraftLoginResponse.accessToken,
//                       ),
//                 ),
//               )
//               .toJson(),
//           reason:
//               'Should copy the expired account with the new tokens without any other changes',
//         );

//         verifyZeroInteractions(_mockAccountStorage);
//       });
//     });

//     test('returns same account if access token has not expired', () async {
//       final fixedDateTime = DateTime(2090, 3, 17, 10);
//       await withClock(Clock.fixed(fixedDateTime), () async {
//         final account = createMinecraftAccount(
//           microsoftAccountInfo: createMicrosoftAccountInfo(
//             minecraftAccessToken: createExpirableToken(
//               expiresAt: fixedDateTime.add(const Duration(days: 1)),
//             ),
//           ),
//         );
//         expect(
//           await refreshMinecraftAccessTokenIfExpired(
//             account,
//             onRefreshProgressUpdate:
//                 (_) => fail(
//                   'Should not refresh the account when the Minecraft access token has not expired.',
//                 ),
//           ),
//           same(account),
//           reason:
//               'Should return the original account if the Minecraft access token has not expired',
//         );

//         verifyZeroInteractions(_mockAccountStorage);
//         verifyZeroInteractions(_mockMinecraftApi);
//         verifyZeroInteractions(_mockMicrosoftAuthApi);
//         verifyZeroInteractions(_mockImageCacheService);
//       });
//     });
//   });
// }

// // WORKAROUND: The APIs provides expiresIn, since the expiresAt depends on
// // on the expiresIn, there is very short delay when
// // fromMinecraftProfileResponse called in production code and in the test
// // code, creating a difference, ignore the difference by trimming the seconds.
// MinecraftAccount _trimSecondsFromAccountExpireAtDateTimes(
//   MinecraftAccount account,
// ) {
//   final microsoftAccountInfo = account.microsoftAccountInfo;
//   return account.copyWith(
//     microsoftAccountInfo: microsoftAccountInfo?.copyWith(
//       microsoftOAuthAccessToken: microsoftAccountInfo.microsoftOAuthAccessToken
//           .copyWith(
//             expiresAt:
//                 microsoftAccountInfo.microsoftOAuthAccessToken.expiresAt
//                     .trimSeconds(),
//           ),
//       microsoftOAuthRefreshToken: microsoftAccountInfo
//           .microsoftOAuthRefreshToken
//           .copyWith(
//             expiresAt:
//             // WORKAROUND: Using fixed DateTime to avoid comparing the refresh token expiresAt.
//             DateTime(2015),
//             // microsoftAccountInfo.microsoftOAuthRefreshToken.expiresAt
//             //     .trimSeconds(),
//           ),
//       minecraftAccessToken: microsoftAccountInfo.minecraftAccessToken.copyWith(
//         expiresAt:
//             microsoftAccountInfo.minecraftAccessToken.expiresAt.trimSeconds(),
//       ),
//     ),
//   );
// }

// extension _MinecraftAccountExt on MinecraftAccount {
//   JsonObject toComparableJson() =>
//       _trimSecondsFromAccountExpireAtDateTimes(this).toJson();
// }

// extension _MinecraftAccountsExt on MinecraftAccounts {
//   MinecraftAccounts _trimSecondsFromAccountsExpireAtDateTimes(
//     MinecraftAccounts accounts,
//   ) => accounts.copyWith(
//     list:
//         accounts.list
//             .map((account) => _trimSecondsFromAccountExpireAtDateTimes(account))
//             .toList(),
//   );

//   JsonObject toComparableJson() =>
//       _trimSecondsFromAccountsExpireAtDateTimes(this).toJson();
// }

// // Tests for all functions that uses _transformExceptions
// void _transformExceptionCommonTests(
//   _MockMinecraftApi Function() mockMinecraftApi,
//   _MockMicrosoftAuthApi Function() mockMicrosoftAuthApi,
//   Future<void> Function() action,
// ) {
//   test(
//     'throws $MinecraftApiAccountManagerException on $MinecraftApiException',
//     () async {
//       final minecraftApiException = MinecraftApiException.tooManyRequests();
//       when(
//         () => mockMinecraftApi().fetchMinecraftProfile(any()),
//       ).thenAnswer((_) async => throw minecraftApiException);
//       await expectLater(
//         action(),
//         throwsA(
//           isA<MinecraftApiAccountManagerException>().having(
//             (e) => e.minecraftApiException,
//             'minecraftApiException',
//             equals(minecraftApiException),
//           ),
//         ),
//       );
//     },
//   );

//   test(
//     'throws $MicrosoftApiAccountManagerException on $MicrosoftAuthException',
//     () async {
//       final microsoftAuthException = MicrosoftAuthException.authCodeExpired();
//       when(
//         () => mockMicrosoftAuthApi().requestXboxLiveToken(any()),
//       ).thenAnswer((_) async => throw microsoftAuthException);
//       await expectLater(
//         action(),
//         throwsA(
//           isA<MicrosoftApiAccountManagerException>().having(
//             (e) => e.authApiException,
//             'microsoftAuthException',
//             equals(microsoftAuthException),
//           ),
//         ),
//       );
//     },
//   );

//   test('throws $UnknownAccountManagerException on $Exception', () async {
//     final exception = Exception('Hello, World!');
//     when(
//       () => mockMicrosoftAuthApi().requestXboxLiveToken(any()),
//     ).thenAnswer((_) async => throw exception);
//     await expectLater(
//       action(),
//       throwsA(
//         isA<UnknownAccountManagerException>().having(
//           (e) => e.message,
//           'message',
//           equals(exception.toString()),
//         ),
//       ),
//     );
//   });

//   test('rethrows $AccountManagerException when caught', () async {
//     final exception = AccountManagerException.unknown(
//       'Unknown',
//       StackTrace.current,
//     );

//     when(
//       () => mockMicrosoftAuthApi().requestXboxLiveToken(any()),
//     ).thenAnswer((_) async => throw exception);

//     await expectLater(
//       action(),
//       throwsA(
//         isA<UnknownAccountManagerException>().having(
//           (e) => e.message,
//           'message',
//           equals(exception.toString()),
//         ),
//       ),
//     );
//   });
// }

// // Common tests for login with auth and device code. The tests of refresh account are slightly different.
// void _commonLoginMicrosoftTests({
//   required Future<AccountResult?> Function() performLoginAction,
//   required void Function(MinecraftAccount newAccount)
//   mockMinecraftAccountCallback,
// }) {
//   test(
//     'saves and returns the account correctly on success when there are no accounts previously',
//     () async {
//       when(
//         () => _mockAccountStorage.loadAccounts(),
//       ).thenReturn(MinecraftAccounts.empty());

//       final newAccount = MinecraftDummyAccount.account;

//       mockMinecraftAccountCallback(newAccount);

//       final result = await performLoginAction();

//       if (result == null) {
//         fail('The result should not be fails when logging using auth code');
//       }

//       verify(() => _mockAccountStorage.loadAccounts()).called(1);
//       verify(
//         () => _mockAccountStorage.saveAccounts(result.updatedAccounts),
//       ).called(1);
//       verifyNoMoreInteractions(_mockAccountStorage);

//       expect(result.updatedAccounts.list.length, 1);
//       expect(
//         result.updatedAccounts.toComparableJson(),
//         MinecraftAccounts(
//           list: [newAccount],
//           defaultAccountId: newAccount.id,
//         ).toComparableJson(),
//       );
//       expect(
//         result.newAccount.toComparableJson(),
//         newAccount.toComparableJson(),
//       );
//     },
//   );

//   test(
//     'saves and returns the account correctly on success when there are accounts previously',
//     () async {
//       final currentDefaultAccountId =
//           MinecraftDummyAccounts.accounts.defaultAccountId!;

//       final existingAccounts = MinecraftDummyAccounts.accounts;

//       when(
//         () => _mockAccountStorage.loadAccounts(),
//       ).thenReturn(existingAccounts);

//       final newAccount = MinecraftDummyAccount.account;

//       mockMinecraftAccountCallback(newAccount);

//       final result = await performLoginAction();

//       if (result == null) {
//         fail('The result should not be fails when logging using auth code');
//       }

//       verify(() => _mockAccountStorage.loadAccounts()).called(1);
//       verify(
//         () => _mockAccountStorage.saveAccounts(result.updatedAccounts),
//       ).called(1);
//       verifyNoMoreInteractions(_mockAccountStorage);

//       expect(
//         result.updatedAccounts.list.length,
//         existingAccounts.list.length + 1,
//       );

//       expect(
//         result.updatedAccounts.toComparableJson(),
//         MinecraftAccounts(
//           list: [newAccount, ...existingAccounts.list],
//           defaultAccountId: currentDefaultAccountId,
//         ).toComparableJson(),
//       );
//       expect(
//         result.newAccount.toComparableJson(),
//         newAccount.toComparableJson(),
//       );
//     },
//   );

//   test(
//     'updates and returns the existing account on success when there are accounts previously',
//     () async {
//       const existingAccountId = MinecraftDummyAccounts.targetAccountId;

//       final existingAccounts = MinecraftDummyAccounts.accounts;

//       when(
//         () => _mockAccountStorage.loadAccounts(),
//       ).thenReturn(existingAccounts);

//       final newAccount = MinecraftDummyAccount.account.copyWith(
//         id: existingAccountId,
//       );

//       mockMinecraftAccountCallback(newAccount);

//       final result = await performLoginAction();

//       if (result == null) {
//         fail('The result should not be fails when logging using auth code');
//       }

//       verify(() => _mockAccountStorage.loadAccounts()).called(1);
//       verify(
//         () => _mockAccountStorage.saveAccounts(result.updatedAccounts),
//       ).called(1);
//       verifyNoMoreInteractions(_mockAccountStorage);

//       expect(result.updatedAccounts.list.length, existingAccounts.list.length);

//       final existingAccountIndex = existingAccounts.list.indexWhere(
//         (account) => account.id == existingAccountId,
//       );

//       expect(
//         result.updatedAccounts.toComparableJson(),
//         existingAccounts
//             .copyWith(
//               list: List.from(existingAccounts.list)
//                 ..[existingAccountIndex] = newAccount,
//             )
//             .toComparableJson(),
//       );
//       expect(result.newAccount.id, existingAccountId);
//     },
//   );
// }

// class MockImageCacheService extends Mock implements ImageCacheService {}

// void _minecraftOwnershipTests({
//   required Future<AccountResult?> Function() performAuthAction,
// }) {
//   test(
//     'ownsMinecraft is true when the user have a valid copy of the game',
//     () async {
//       const ownsMinecraft = true;
//       when(
//         () => _mockMinecraftApi.checkMinecraftJavaOwnership(any()),
//       ).thenAnswer((_) async => ownsMinecraft);

//       final result = await performAuthAction();
//       expect(result?.newAccount.ownsMinecraftJava, ownsMinecraft);
//     },
//   );

//   test(
//     'throws $MinecraftEntitlementAbsentAccountManagerException when the user dont have a valid copy of the game',
//     () async {
//       const ownsMinecraft = false;
//       when(
//         () => _mockMinecraftApi.checkMinecraftJavaOwnership(any()),
//       ).thenAnswer((_) async => ownsMinecraft);

//       await expectLater(
//         performAuthAction(),
//         throwsA(isA<MinecraftEntitlementAbsentAccountManagerException>()),
//       );
//     },
//   );
// }

// void _minecraftAccountCreationFromApiResponsesTest(
//   Future<AccountResult?> Function(
//     MicrosoftOauthTokenExchangeResponse microsoftOauthResponse,
//   )
//   performAuthAction, {
//   // Only set this when using fakeAsync() that uses async.elapse()
//   Duration elapsed = Duration.zero,
// }) {
//   test('returns Minecraft account correctly based on the API responses', () async {
//     const microsoftOauthResponse = MicrosoftOauthTokenExchangeResponse(
//       accessToken: 'accessTokedadsdandsadsadas',
//       refreshToken: 'refreshToken2dasdsadsadsadsadsa',
//       expiresIn: 4000,
//     );

//     const minecraftLoginResponse = MinecraftLoginResponse(
//       username: 'dsadsadspmiidsadsadsa90i90a',
//       accessToken: 'dsadsadsadsas0opoplkopspaoasdsadsad321312321',
//       expiresIn: 9600,
//     );

//     const minecraftProfileResponse = MinecraftProfileResponse(
//       id: 'dsadsadsadsa',
//       name: 'Alex',
//       skins: [
//         MinecraftProfileSkin(
//           id: 'id',
//           state: MinecraftCosmeticState.inactive,
//           url: 'http://edsadsaxample',
//           textureKey: 'dsadsadsasdsads',
//           variant: MinecraftSkinVariant.slim,
//         ),
//         MinecraftProfileSkin(
//           id: 'id2',
//           state: MinecraftCosmeticState.active,
//           url: 'http://exdsadsaample2',
//           textureKey: 'dsadsadsads',
//           variant: MinecraftSkinVariant.classic,
//         ),
//       ],
//       capes: [
//         MinecraftProfileCape(
//           id: 'id',
//           state: MinecraftCosmeticState.active,
//           url: 'http://example',
//           alias: 'dasdsadas',
//         ),
//       ],
//     );

//     const ownsMinecraftJava = true;

//     when(
//       () => _mockMinecraftApi.loginToMinecraftWithXbox(any()),
//     ).thenAnswer((_) async => minecraftLoginResponse);
//     when(
//       () => _mockMinecraftApi.fetchMinecraftProfile(any()),
//     ).thenAnswer((_) async => minecraftProfileResponse);
//     when(
//       () => _mockMinecraftApi.checkMinecraftJavaOwnership(any()),
//     ).thenAnswer((_) async => ownsMinecraftJava);

//     final fixedDateTime = DateTime(2080, 8, 3, 10);
//     await withClock(Clock.fixed(fixedDateTime), () async {
//       final result = await performAuthAction(microsoftOauthResponse);
//       final microsoftAccountInfo = result?.newAccount.microsoftAccountInfo;

//       expect(
//         microsoftAccountInfo?.minecraftAccessToken.expiresAt,
//         fixedDateTime
//             .add(Duration(seconds: minecraftLoginResponse.expiresIn))
//             .add(elapsed),
//         reason:
//             'The minecraftAccessToken should be: current date + ${minecraftLoginResponse.expiresIn}s which is the expiresIn from the API response',
//       );
//       expect(
//         microsoftAccountInfo?.microsoftOAuthRefreshToken.expiresAt,
//         fixedDateTime
//             .add(
//               const Duration(
//                 days: MicrosoftConstants.refreshTokenExpiresInDays,
//               ),
//             )
//             .add(elapsed),
//         reason:
//             'The microsoftOAuthRefreshToken should be: current date + ${MicrosoftConstants.refreshTokenExpiresInDays} days',
//       );

//       expect(
//         result?.newAccount.toComparableJson(),
//         _minecraftAccountManager
//             .accountFromResponses(
//               profileResponse: minecraftProfileResponse,
//               oauthTokenResponse: microsoftOauthResponse,
//               loginResponse: minecraftLoginResponse,
//               ownsMinecraftJava: ownsMinecraftJava,
//             )
//             .toComparableJson(),
//       );
//     });
//   });
// }

// // TODO: This should be Microsoft account re-auth with the correct reason. This is outdated with the production code
// void _testRefreshAccountWithExpiredOrRevokedMicrosoftAccount(
//   Future<void> Function(MinecraftAccount account) performRefresh,
// ) {
//   test(
//     'throws $MicrosoftRefreshTokenExpiredAccountManagerException when account needs refresh due to expiration or revoked access',
//     () async {
//       await expectLater(
//         performRefresh(
//           createMinecraftAccount(
//             microsoftAccountInfo: createMicrosoftAccountInfo(
//               needsReAuthentication: true,
//             ),
//           ),
//         ),
//         throwsA(isA<MicrosoftRefreshTokenExpiredAccountManagerException>()),
//       );
//     },
//   );
// }

// enum _TestAuthAction { refreshAccount, loginWithAuthCode, loginWithDeviceCode }
