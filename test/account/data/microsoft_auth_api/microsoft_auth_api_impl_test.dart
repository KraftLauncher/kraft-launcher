import 'dart:io';

import 'package:dio/dio.dart';
import 'package:kraft_launcher/account/data/microsoft_auth_api/auth_methods/microsoft_device_code_flow.dart';
import 'package:kraft_launcher/account/data/microsoft_auth_api/microsoft_auth_api.dart';
import 'package:kraft_launcher/account/data/microsoft_auth_api/microsoft_auth_api_impl.dart';
import 'package:kraft_launcher/account/data/microsoft_auth_api/microsoft_auth_exceptions.dart';
import 'package:kraft_launcher/common/constants/constants.dart';
import 'package:kraft_launcher/common/constants/project_info_constants.dart';
import 'package:kraft_launcher/common/logic/json.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../common/helpers/dio_utils.dart';

void main() {
  late MicrosoftAuthApi microsoftAuthApi;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    microsoftAuthApi = MicrosoftAuthApiImpl(dio: mockDio);
  });

  setUpAll(() {
    registerFallbackValue(Uri.https('dummy-instance.com'));
  });

  // START Auth code

  test('userLoginUrlWithAuthCode returns the URL correctly', () {
    expect(
      microsoftAuthApi.userLoginUrlWithAuthCode(),
      'https://login.live.com/oauth20_authorize.srf?client_id=${ProjectInfoConstants.microsoftLoginClientId}&response_type=code&redirect_uri=${Uri.encodeComponent(MicrosoftConstants.loginRedirectUrl)}&scope=${MicrosoftConstants.loginScopes.split(' ').join('+')}',
    );
  });

  group('exchangeAuthCodeForTokens', () {
    const fakeAuthCode = 'M.C512_SN1.3.T.169e4c91-7750-17d2-017e-707401144e73';

    test(
      'uses expected request URI, headers, and body with the auth code',
      () async {
        mockDio.mockPostUriSuccess<JsonObject>(
          responseData: {
            'access_token': 'Access Token',
            'refresh_token': 'Refresh TOken',
            'expires_in': 3600,
          },
        );

        await microsoftAuthApi.exchangeAuthCodeForTokens(fakeAuthCode);
        final captured =
            mockDio.capturePostUriArguments<JsonObject, JsonObject>();

        expect(
          captured.options?.headers,
          Options(
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          ).headers,
        );
        expect(captured.requestData['code'], fakeAuthCode);
        expect(captured.uri, Uri.https('login.live.com', '/oauth20_token.srf'));
        expect(captured.requestData, {
          'client_id': ProjectInfoConstants.microsoftLoginClientId,
          'grant_type': 'authorization_code',
          'code': fakeAuthCode,
          'redirect_uri': MicrosoftConstants.loginRedirectUrl,
          'scope': MicrosoftConstants.loginScopes,
        });
      },
    );

    test(
      'returns parsed $MicrosoftOauthTokenExchangeResponse on success',
      () async {
        const expiresIn = 3600;
        const accessToken = 'Example Access Token';
        const refreshToken = 'Example Refresh Token';
        mockDio.mockPostUriSuccess<JsonObject>(
          responseData: {
            'access_token': accessToken,
            'refresh_token': refreshToken,
            'expires_in': expiresIn,
          },
        );

        final response = await microsoftAuthApi.exchangeAuthCodeForTokens(
          fakeAuthCode,
        );

        expect(response.accessToken, accessToken);
        expect(response.refreshToken, refreshToken);
        expect(response.expiresIn, expiresIn);
      },
    );

    test(
      'throws $AuthCodeExpiredMicrosoftAuthException when auth code expires',
      () async {
        mockDio.mockPostUriFailure<JsonObject>(
          responseData: {'error': 'invalid_grant'},
        );

        await expectLater(
          microsoftAuthApi.exchangeAuthCodeForTokens(fakeAuthCode),
          throwsA(isA<AuthCodeExpiredMicrosoftAuthException>()),
        );
      },
    );

    _tooManyRequestsTest(
      () => mockDio,
      () => microsoftAuthApi.exchangeAuthCodeForTokens(fakeAuthCode),
    );

    _unknownErrorTests(
      () => mockDio,
      () => microsoftAuthApi.exchangeAuthCodeForTokens(fakeAuthCode),
    );
  });

  // END: Auth code

  // START: Device code

  group('requestDeviceCode', () {
    test('uses expected request URI, headers, and body', () async {
      mockDio.mockPostUriSuccess<JsonObject>(
        responseData: {
          'user_code': 'User code',
          'device_code': 'Device Code',
          'expires_in': 3600,
          'interval': 5,
        },
      );

      await microsoftAuthApi.requestDeviceCode();
      final captured =
          mockDio.capturePostUriArguments<JsonObject, JsonObject>();

      expect(
        captured.options?.headers,
        Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ).headers,
      );
      expect(
        captured.uri,
        Uri.https(
          'login.microsoftonline.com',
          '/consumers/oauth2/v2.0/devicecode',
        ),
      );
      expect(captured.requestData, {
        'client_id': ProjectInfoConstants.microsoftLoginClientId,
        'scope': MicrosoftConstants.loginScopes,
      });
    });

    test(
      'returns parsed $MicrosoftRequestDeviceCodeResponse on success',
      () async {
        const expiresIn = 3600;
        const interval = 5;
        const userCode = 'User code';
        const deviceCode = 'Device code';
        mockDio.mockPostUriSuccess<JsonObject>(
          responseData: {
            'user_code': userCode,
            'device_code': deviceCode,
            'expires_in': expiresIn,
            'interval': interval,
          },
        );

        final response = await microsoftAuthApi.requestDeviceCode();

        expect(response.deviceCode, deviceCode);
        expect(response.userCode, userCode);
        expect(response.expiresIn, expiresIn);
        expect(response.interval, interval);
      },
    );

    _tooManyRequestsTest(
      () => mockDio,
      () => microsoftAuthApi.requestDeviceCode(),
    );
    _unknownErrorTests(
      () => mockDio,
      () => microsoftAuthApi.requestDeviceCode(),
    );
  });

  group('checkDeviceCodeStatus', () {
    MicrosoftRequestDeviceCodeResponse requestDeviceCodeResponse({
      required String deviceCode,
    }) => MicrosoftRequestDeviceCodeResponse(
      deviceCode: deviceCode,
      userCode: '',
      expiresIn: -1,
      interval: -1,
    );
    test(
      'uses expected request URI, headers, and body with the device code',
      () async {
        mockDio.mockPostUriSuccess<JsonObject>(
          responseData: {
            'access_token': 'Access token',
            'refresh_token': 'Refresh Token',
            'expires_in': 3600,
          },
        );

        const deviceCode = 'Example Device code';
        await microsoftAuthApi.checkDeviceCodeStatus(
          requestDeviceCodeResponse(deviceCode: deviceCode),
        );
        final captured =
            mockDio.capturePostUriArguments<JsonObject, JsonObject>();

        expect(
          captured.options?.headers,
          Options(
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          ).headers,
        );
        expect(
          captured.uri,
          Uri.https(
            'login.microsoftonline.com',
            '/consumers/oauth2/v2.0/token',
          ),
        );
        expect(captured.requestData['device_code'], deviceCode);
        expect(captured.requestData, {
          'client_id': ProjectInfoConstants.microsoftLoginClientId,
          'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
          'device_code': deviceCode,
        });
      },
    );

    test('returns $MicrosoftDeviceCodeSuccess on success', () async {
      const accessToken = 'Example access token';
      const refreshToken = 'Example refresh token';
      const expiresIn = 3600;
      mockDio.mockPostUriSuccess<JsonObject>(
        responseData: {
          'access_token': accessToken,
          'refresh_token': refreshToken,
          'expires_in': expiresIn,
        },
      );

      const deviceCode = 'Example Device code';
      final result = await microsoftAuthApi.checkDeviceCodeStatus(
        requestDeviceCodeResponse(deviceCode: deviceCode),
      );

      expect(result, isA<MicrosoftDeviceCodeSuccess>());

      final successResponse = (result as MicrosoftDeviceCodeSuccess).response;
      expect(successResponse.accessToken, accessToken);
      expect(successResponse.refreshToken, refreshToken);
      expect(successResponse.expiresIn, expiresIn);
    });

    test(
      'returns $MicrosoftDeviceCodeAuthorizationPending when Microsoft awaiting the user',
      () async {
        mockDio.mockPostUriFailure<JsonObject>(
          responseData: {'error': 'authorization_pending'},
        );

        final result = await microsoftAuthApi.checkDeviceCodeStatus(
          requestDeviceCodeResponse(deviceCode: 'any'),
        );
        expect(result, isA<MicrosoftDeviceCodeAuthorizationPending>());
      },
    );
    test(
      'returns $MicrosoftDeviceCodeExpired when user device code expires',
      () async {
        mockDio.mockPostUriFailure<JsonObject>(
          responseData: {'error': 'expired_token'},
        );

        final result = await microsoftAuthApi.checkDeviceCodeStatus(
          requestDeviceCodeResponse(deviceCode: 'any'),
        );
        expect(result, isA<MicrosoftDeviceCodeExpired>());
      },
    );

    _tooManyRequestsTest(
      () => mockDio,
      () => microsoftAuthApi.checkDeviceCodeStatus(
        requestDeviceCodeResponse(deviceCode: 'any'),
      ),
    );

    _unknownErrorTests(
      () => mockDio,
      () => microsoftAuthApi.checkDeviceCodeStatus(
        requestDeviceCodeResponse(deviceCode: 'any'),
      ),
    );
  });

  // END: Device code

  // START: Xbox

  group('requestXboxLiveToken', () {
    MicrosoftOauthTokenExchangeResponse microsoftOauthTokenResponse({
      required String accessToken,
    }) => MicrosoftOauthTokenExchangeResponse(
      accessToken: accessToken,
      refreshToken: '',
      expiresIn: -1,
    );
    test(
      'uses expected request URI, headers, and body with the Microsoft access token',
      () async {
        mockDio.mockPostUriSuccess<JsonObject>(
          responseData: {
            'Token': '',
            'DisplayClaims': {
              'xui': [
                {'uhs': ''},
              ],
            },
          },
        );

        const microsoftAccessToken = 'Example Access Token';
        await microsoftAuthApi.requestXboxLiveToken(
          microsoftOauthTokenResponse(accessToken: microsoftAccessToken),
        );
        final captured =
            mockDio.capturePostUriArguments<JsonObject, JsonObject>();

        expect(
          captured.options?.headers,
          Options(
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ).headers,
        );
        expect(
          captured.uri,
          Uri.https('user.auth.xboxlive.com', '/user/authenticate'),
        );
        expect(
          (captured.requestData['Properties'] as JsonObject?)?['RpsTicket'],
          'd=$microsoftAccessToken',
        );
        expect(captured.requestData, {
          'Properties': {
            'AuthMethod': 'RPS',
            'SiteName': 'user.auth.xboxlive.com',
            'RpsTicket': 'd=$microsoftAccessToken',
          },
          'RelyingParty': 'http://auth.xboxlive.com',
          'TokenType': 'JWT',
        });
      },
    );

    test('returns parsed $XboxLiveAuthTokenResponse on success', () async {
      const token = 'Xbox Live token';
      const userHash = 'User Hash';
      mockDio.mockPostUriSuccess<JsonObject>(
        responseData: {
          'Token': token,
          'DisplayClaims': {
            'xui': [
              {'uhs': userHash},
            ],
          },
        },
      );

      final response = await microsoftAuthApi.requestXboxLiveToken(
        microsoftOauthTokenResponse(accessToken: ''),
      );

      expect(response.userHash, userHash);
      expect(response.xboxToken, token);
    });

    test(
      'throws $XboxTokenRequestFailedDueToExpiredAccessTokenMicrosoftAuthException when Microsoft OAuth access token expires',
      () async {
        mockDio.mockPostUriFailure<JsonObject>(
          headers: Headers.fromMap({
            'Www-Authenticate': ['XASU error=token_expired'],
          }),
          responseData: {},
        );

        await expectLater(
          () => microsoftAuthApi.requestXboxLiveToken(
            microsoftOauthTokenResponse(accessToken: ''),
          ),
          throwsA(
            isA<
              XboxTokenRequestFailedDueToExpiredAccessTokenMicrosoftAuthException
            >(),
          ),
        );
      },
    );

    _tooManyRequestsTest(
      () => mockDio,
      () => microsoftAuthApi.requestXboxLiveToken(
        microsoftOauthTokenResponse(accessToken: ''),
      ),
    );
    _unknownErrorTests(
      () => mockDio,
      () => microsoftAuthApi.requestXboxLiveToken(
        microsoftOauthTokenResponse(accessToken: ''),
      ),
    );
  });

  group('requestXSTSToken', () {
    XboxLiveAuthTokenResponse xboxLiveTokenResponse({String xboxToken = ''}) =>
        XboxLiveAuthTokenResponse(xboxToken: xboxToken, userHash: '');
    test(
      'uses expected request URI, headers, and body with the Xbox Live token',
      () async {
        mockDio.mockPostUriSuccess<JsonObject>(
          responseData: {
            'Token': '',
            'DisplayClaims': {
              'xui': [
                {'uhs': ''},
              ],
            },
          },
        );

        const xboxLiveToken = 'Example Xbox Live Token';
        await microsoftAuthApi.requestXSTSToken(
          xboxLiveTokenResponse(xboxToken: xboxLiveToken),
        );
        final captured =
            mockDio.capturePostUriArguments<JsonObject, JsonObject>();

        expect(
          captured.options?.headers,
          Options(
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ).headers,
        );
        expect(
          captured.uri,
          Uri.https('xsts.auth.xboxlive.com', '/xsts/authorize'),
        );
        expect(
          ((captured.requestData['Properties'] as JsonObject?)!['UserTokens']!
                  as List)
              .firstOrNull,
          xboxLiveToken,
        );
        expect(captured.requestData, {
          'Properties': {
            'SandboxId': 'RETAIL',
            'UserTokens': [xboxLiveToken],
          },
          'RelyingParty': 'rp://api.minecraftservices.com/',
          'TokenType': 'JWT',
        });
      },
    );

    test('returns parsed $XboxLiveAuthTokenResponse on success', () async {
      const token = 'Xbox Live token';
      const userHash = 'User Hash';
      mockDio.mockPostUriSuccess<JsonObject>(
        responseData: {
          'Token': token,
          'DisplayClaims': {
            'xui': [
              {'uhs': userHash},
            ],
          },
        },
      );

      final response = await microsoftAuthApi.requestXSTSToken(
        xboxLiveTokenResponse(),
      );

      expect(response.userHash, userHash);
      expect(response.xboxToken, token);
    });

    _tooManyRequestsTest(
      () => mockDio,
      () => microsoftAuthApi.requestXSTSToken(xboxLiveTokenResponse()),
    );
    _unknownErrorTests(
      () => mockDio,
      () => microsoftAuthApi.requestXSTSToken(xboxLiveTokenResponse()),
    );

    test(
      'throws $XstsErrorMicrosoftAuthException for Xbox specific errors',
      () async {
        for (final xstsError in XstsError.values) {
          const message = 'An unknown error';
          mockDio.mockPostUriFailure<JsonObject>(
            statusCode: HttpStatus.unauthorized,
            responseData: {'Message': message, 'XErr': xstsError.xErr},
          );

          await expectLater(
            microsoftAuthApi.requestXSTSToken(xboxLiveTokenResponse()),
            throwsA(
              isA<XstsErrorMicrosoftAuthException>()
                  .having((e) => e.message, 'message', message)
                  .having((e) => e.xErr, 'xErr', xstsError.xErr)
                  .having((e) => e.xstsError, 'xstsError', xstsError),
            ),
          );
        }
      },
    );
  });

  // END: Xbox

  group('getNewTokensFromRefreshToken', () {
    test(
      'uses expected request URI, headers, and body with the refresh token',
      () async {
        mockDio.mockPostUriSuccess<JsonObject>(
          responseData: {
            'access_token': '',
            'refresh_token': '',
            'expires_in': -1,
          },
        );

        const microsoftOauthRefreshToken = 'Example Microsoft Refresh Token';

        await microsoftAuthApi.getNewTokensFromRefreshToken(
          microsoftOauthRefreshToken,
        );
        final captured =
            mockDio.capturePostUriArguments<JsonObject, JsonObject>();

        expect(
          captured.options?.headers,
          Options(
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          ).headers,
        );
        expect(
          captured.requestData['refresh_token'],
          microsoftOauthRefreshToken,
        );
        expect(captured.uri, Uri.https('login.live.com', '/oauth20_token.srf'));
        expect(captured.requestData, {
          'client_id': ProjectInfoConstants.microsoftLoginClientId,
          'grant_type': 'refresh_token',
          'refresh_token': microsoftOauthRefreshToken,
        });
      },
    );

    test(
      'returns parsed $MicrosoftOauthTokenExchangeResponse on success',
      () async {
        const expiresIn = 3600;
        const accessToken = 'Example Microsoft Access Token';
        const refreshToken = 'Example Microsoft Refresh Token';
        mockDio.mockPostUriSuccess<JsonObject>(
          responseData: {
            'access_token': accessToken,
            'refresh_token': refreshToken,
            'expires_in': expiresIn,
          },
        );

        final response = await microsoftAuthApi.getNewTokensFromRefreshToken(
          '',
        );

        expect(response.accessToken, accessToken);
        expect(response.refreshToken, refreshToken);
        expect(response.expiresIn, expiresIn);
      },
    );

    test(
      'throws $ExpiredOrUnauthorizedRefreshTokenMicrosoftAuthException when refresh token expires',
      () async {
        mockDio.mockPostUriFailure<JsonObject>(
          responseData: {'error': 'invalid_grant'},
        );

        await expectLater(
          microsoftAuthApi.getNewTokensFromRefreshToken(''),
          throwsA(
            isA<ExpiredOrUnauthorizedRefreshTokenMicrosoftAuthException>(),
          ),
        );
      },
    );

    _tooManyRequestsTest(
      () => mockDio,
      () => microsoftAuthApi.getNewTokensFromRefreshToken(''),
    );

    _unknownErrorTests(
      () => mockDio,
      () => microsoftAuthApi.getNewTokensFromRefreshToken(''),
    );
  });
}

void _tooManyRequestsTest(
  MockDio Function() mockDio,
  Future<void> Function() call,
) {
  test(
    'throws $TooManyRequestsMicrosoftAuthException on HTTP ${HttpStatus.tooManyRequests}',
    () async {
      mockDio().mockPostUriFailure<JsonObject>(
        statusCode: HttpStatus.tooManyRequests,
        responseData: {},
      );

      await expectLater(
        call,
        throwsA(isA<TooManyRequestsMicrosoftAuthException>()),
      );
    },
  );
}

void _unknownErrorTests(
  MockDio Function() mockDio,
  Future<void> Function() call,
) {
  test(
    'throws $UnknownMicrosoftAuthException for unhandled or unknown errors with code and description when provided',
    () async {
      const errorCode = 'unknown_error_code';
      const errorDescription = 'The unknown error description';
      mockDio().mockPostUriFailure<JsonObject>(
        responseData: {
          'error': errorCode,
          'error_description': errorDescription,
        },
      );

      await expectLater(
        call,
        throwsA(
          isA<UnknownMicrosoftAuthException>()
              .having((e) => e.message, 'errorCode', contains(errorCode))
              .having(
                (e) => e.message,
                'description',
                contains(errorDescription),
              ),
        ),
      );
    },
  );

  test(
    'throws $UnknownMicrosoftAuthException for unhandled or unknown errors without code and description when not provided',
    () async {
      mockDio().mockPostUriFailure<JsonObject>(responseData: {});

      await expectLater(call, throwsA(isA<UnknownMicrosoftAuthException>()));
    },
  );

  test(
    'throws $UnknownMicrosoftAuthException when catching $Exception',
    () async {
      final exception = Exception('Example exception');
      mockDio().mockPostUriFailure<JsonObject>(
        responseData: null,
        customException: exception,
      );

      await expectLater(
        call,
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            equals(exception.toString()),
          ),
        ),
      );
    },
  );
}
