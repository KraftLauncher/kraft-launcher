import 'dart:io';

import 'package:dio/dio.dart';
import 'package:kraft_launcher/account/data/microsoft_auth_api/auth_flows/microsoft_device_code_flow_api.dart';
import 'package:kraft_launcher/account/data/microsoft_auth_api/microsoft_auth_api.dart';
import 'package:kraft_launcher/account/data/microsoft_auth_api/microsoft_auth_api_exceptions.dart'
    as microsoft_auth_api_exceptions;
import 'package:kraft_launcher/account/data/microsoft_auth_api/microsoft_auth_api_impl.dart';
import 'package:kraft_launcher/common/constants/constants.dart';
import 'package:kraft_launcher/common/constants/project_info_constants.dart';
import 'package:kraft_launcher/common/data/json.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../common/helpers/dio_utils.dart';
import '../../../common/test_constants.dart';

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
        mockDio.mockPostUriSuccess<JsonMap>(
          responseData: {
            'access_token': 'Access Token',
            'refresh_token': 'Refresh TOken',
            'expires_in': 3600,
          },
        );

        await microsoftAuthApi.exchangeAuthCodeForTokens(fakeAuthCode);
        final captured = mockDio.capturePostUriArguments<JsonMap, JsonMap>();

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

    test('returns parsed $MicrosoftOAuthTokenResponse on success', () async {
      const expiresIn = 3600;
      const accessToken = 'Example Access Token';
      const refreshToken = 'Example Refresh Token';
      mockDio.mockPostUriSuccess<JsonMap>(
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
    });

    test(
      'throws ${microsoft_auth_api_exceptions.AuthCodeExpiredException} when auth code expires',
      () async {
        mockDio.mockPostUriFailure<JsonMap>(
          responseData: {'error': 'invalid_grant'},
        );

        await expectLater(
          microsoftAuthApi.exchangeAuthCodeForTokens(fakeAuthCode),
          throwsA(
            isA<microsoft_auth_api_exceptions.AuthCodeExpiredException>(),
          ),
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
      mockDio.mockPostUriSuccess<JsonMap>(
        responseData: {
          'user_code': 'User code',
          'device_code': 'Device Code',
          'expires_in': 3600,
          'interval': 5,
        },
      );

      await microsoftAuthApi.requestDeviceCode();
      final captured = mockDio.capturePostUriArguments<JsonMap, JsonMap>();

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
        mockDio.mockPostUriSuccess<JsonMap>(
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
        mockDio.mockPostUriSuccess<JsonMap>(
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
        final captured = mockDio.capturePostUriArguments<JsonMap, JsonMap>();

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

    test(
      'returns $MicrosoftDeviceCodeApproved when the user approves the authorization request',
      () async {
        const accessToken = 'Example access token';
        const refreshToken = 'Example refresh token';
        const expiresIn = 3600;
        mockDio.mockPostUriSuccess<JsonMap>(
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

        expect(result, isA<MicrosoftDeviceCodeApproved>());

        final successResponse =
            (result as MicrosoftDeviceCodeApproved).response;
        expect(successResponse.accessToken, accessToken);
        expect(successResponse.refreshToken, refreshToken);
        expect(successResponse.expiresIn, expiresIn);
      },
    );

    test(
      'returns $MicrosoftDeviceCodeDeclined when the user declines the authorization request',
      () async {
        mockDio.mockPostUriFailure<JsonMap>(
          responseData: {'error': 'authorization_declined'},
        );

        final result = await microsoftAuthApi.checkDeviceCodeStatus(
          requestDeviceCodeResponse(deviceCode: TestConstants.anyString),
        );
        expect(result, isA<MicrosoftCheckDeviceCodeStatusResult>());
      },
    );

    test(
      'returns $MicrosoftDeviceCodeAuthorizationPending when Microsoft awaiting the user',
      () async {
        mockDio.mockPostUriFailure<JsonMap>(
          responseData: {'error': 'authorization_pending'},
        );

        final result = await microsoftAuthApi.checkDeviceCodeStatus(
          requestDeviceCodeResponse(deviceCode: TestConstants.anyString),
        );
        expect(result, isA<MicrosoftDeviceCodeAuthorizationPending>());
      },
    );
    test(
      'returns $MicrosoftDeviceCodeExpired when user device code expires',
      () async {
        mockDio.mockPostUriFailure<JsonMap>(
          responseData: {'error': 'expired_token'},
        );

        final result = await microsoftAuthApi.checkDeviceCodeStatus(
          requestDeviceCodeResponse(deviceCode: TestConstants.anyString),
        );
        expect(result, isA<MicrosoftDeviceCodeExpired>());
      },
    );

    _tooManyRequestsTest(
      () => mockDio,
      () => microsoftAuthApi.checkDeviceCodeStatus(
        requestDeviceCodeResponse(deviceCode: TestConstants.anyString),
      ),
    );

    _unknownErrorTests(
      () => mockDio,
      () => microsoftAuthApi.checkDeviceCodeStatus(
        requestDeviceCodeResponse(deviceCode: TestConstants.anyString),
      ),
    );
  });

  // END: Device code

  // START: Xbox

  group('requestXboxLiveToken', () {
    test(
      'uses expected request URI, headers, and body with the Microsoft access token',
      () async {
        mockDio.mockPostUriSuccess<JsonMap>(
          responseData: {
            'Token': TestConstants.anyString,
            'DisplayClaims': {
              'xui': [
                {'uhs': TestConstants.anyString},
              ],
            },
          },
        );

        const microsoftAccessToken = 'Example Access Token';
        await microsoftAuthApi.requestXboxLiveToken(microsoftAccessToken);
        final captured = mockDio.capturePostUriArguments<JsonMap, JsonMap>();

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
          (captured.requestData['Properties'] as JsonMap?)?['RpsTicket'],
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
      mockDio.mockPostUriSuccess<JsonMap>(
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
        TestConstants.anyString,
      );

      expect(response.userHash, userHash);
      expect(response.xboxToken, token);
    });

    test(
      'throws ${microsoft_auth_api_exceptions.XboxTokenMicrosoftAccessTokenExpiredException} when Microsoft OAuth access token expires',
      () async {
        mockDio.mockPostUriFailure<JsonMap>(
          headers: Headers.fromMap({
            'Www-Authenticate': ['XASU error=token_expired'],
          }),
          responseData: {},
        );

        await expectLater(
          () => microsoftAuthApi.requestXboxLiveToken(TestConstants.anyString),
          throwsA(
            isA<
              microsoft_auth_api_exceptions.XboxTokenMicrosoftAccessTokenExpiredException
            >(),
          ),
        );
      },
    );

    _tooManyRequestsTest(
      () => mockDio,
      () => microsoftAuthApi.requestXboxLiveToken(TestConstants.anyString),
    );
    _unknownErrorTests(
      () => mockDio,
      () => microsoftAuthApi.requestXboxLiveToken(TestConstants.anyString),
    );
  });

  group('requestXSTSToken', () {
    test(
      'uses expected request URI, headers, and body with the Xbox Live token',
      () async {
        mockDio.mockPostUriSuccess<JsonMap>(
          responseData: {
            'Token': TestConstants.anyString,
            'DisplayClaims': {
              'xui': [
                {'uhs': TestConstants.anyString},
              ],
            },
          },
        );

        const xboxLiveToken = 'Example Xbox Live Token';
        await microsoftAuthApi.requestXSTSToken(xboxLiveToken);
        final captured = mockDio.capturePostUriArguments<JsonMap, JsonMap>();

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
          ((captured.requestData['Properties'] as JsonMap?)!['UserTokens']!
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
      mockDio.mockPostUriSuccess<JsonMap>(
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
        TestConstants.anyString,
      );

      expect(response.userHash, userHash);
      expect(response.xboxToken, token);
    });

    _tooManyRequestsTest(
      () => mockDio,
      () => microsoftAuthApi.requestXSTSToken(TestConstants.anyString),
    );
    _unknownErrorTests(
      () => mockDio,
      () => microsoftAuthApi.requestXSTSToken(TestConstants.anyString),
    );

    test(
      'throws ${microsoft_auth_api_exceptions.XstsErrorException} for Xbox specific errors',
      () async {
        for (final xstsError
            in microsoft_auth_api_exceptions.XstsError.values) {
          const message = 'An unknown error';
          mockDio.mockPostUriFailure<JsonMap>(
            statusCode: HttpStatus.unauthorized,
            responseData: {'Message': message, 'XErr': xstsError.xErr},
          );

          await expectLater(
            microsoftAuthApi.requestXSTSToken(TestConstants.anyString),
            throwsA(
              isA<microsoft_auth_api_exceptions.XstsErrorException>()
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
        mockDio.mockPostUriSuccess<JsonMap>(
          responseData: {
            'access_token': TestConstants.anyString,
            'refresh_token': TestConstants.anyString,
            'expires_in': -1,
          },
        );

        const microsoftRefreshToken = 'Example Microsoft Refresh Token';

        await microsoftAuthApi.getNewTokensFromRefreshToken(
          microsoftRefreshToken,
        );
        final captured = mockDio.capturePostUriArguments<JsonMap, JsonMap>();

        expect(
          captured.options?.headers,
          Options(
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          ).headers,
        );
        expect(captured.requestData['refresh_token'], microsoftRefreshToken);
        expect(captured.uri, Uri.https('login.live.com', '/oauth20_token.srf'));
        expect(captured.requestData, {
          'client_id': ProjectInfoConstants.microsoftLoginClientId,
          'grant_type': 'refresh_token',
          'refresh_token': microsoftRefreshToken,
        });
      },
    );

    test('returns parsed $MicrosoftOAuthTokenResponse on success', () async {
      const expiresIn = 3600;
      const accessToken = 'Example Microsoft Access Token';
      const refreshToken = 'Example Microsoft Refresh Token';
      mockDio.mockPostUriSuccess<JsonMap>(
        responseData: {
          'access_token': accessToken,
          'refresh_token': refreshToken,
          'expires_in': expiresIn,
        },
      );

      final response = await microsoftAuthApi.getNewTokensFromRefreshToken(
        TestConstants.anyString,
      );

      expect(response.accessToken, accessToken);
      expect(response.refreshToken, refreshToken);
      expect(response.expiresIn, expiresIn);
    });

    test(
      'throws ${microsoft_auth_api_exceptions.InvalidRefreshTokenException} when refresh token expires',
      () async {
        mockDio.mockPostUriFailure<JsonMap>(
          responseData: {'error': 'invalid_grant'},
        );

        await expectLater(
          microsoftAuthApi.getNewTokensFromRefreshToken(
            TestConstants.anyString,
          ),
          throwsA(
            isA<microsoft_auth_api_exceptions.InvalidRefreshTokenException>(),
          ),
        );
      },
    );

    _tooManyRequestsTest(
      () => mockDio,
      () => microsoftAuthApi.getNewTokensFromRefreshToken(
        TestConstants.anyString,
      ),
    );

    _unknownErrorTests(
      () => mockDio,
      () => microsoftAuthApi.getNewTokensFromRefreshToken(
        TestConstants.anyString,
      ),
    );
  });
}

void _tooManyRequestsTest(
  MockDio Function() mockDio,
  Future<void> Function() call,
) {
  test(
    'throws ${microsoft_auth_api_exceptions.TooManyRequestsException} on HTTP ${HttpStatus.tooManyRequests}',
    () async {
      mockDio().mockPostUriFailure<JsonMap>(
        statusCode: HttpStatus.tooManyRequests,
        responseData: {},
      );

      await expectLater(
        call,
        throwsA(isA<microsoft_auth_api_exceptions.TooManyRequestsException>()),
      );
    },
  );
}

void _unknownErrorTests(
  MockDio Function() mockDio,
  Future<void> Function() call,
) {
  test(
    'throws ${microsoft_auth_api_exceptions.UnknownException} for unhandled or unknown errors with code and description when provided',
    () async {
      const errorCode = 'unknown_error_code';
      const errorDescription = 'The unknown error description';
      mockDio().mockPostUriFailure<JsonMap>(
        responseData: {
          'error': errorCode,
          'error_description': errorDescription,
        },
      );

      await expectLater(
        call,
        throwsA(
          isA<microsoft_auth_api_exceptions.UnknownException>()
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
    'throws ${microsoft_auth_api_exceptions.UnknownException} for unhandled or unknown errors without code and description when not provided',
    () async {
      mockDio().mockPostUriFailure<JsonMap>(responseData: {});

      await expectLater(
        call,
        throwsA(isA<microsoft_auth_api_exceptions.UnknownException>()),
      );
    },
  );

  test(
    'throws ${microsoft_auth_api_exceptions.UnknownException} when catching $Exception',
    () async {
      final exception = Exception('Example exception');
      mockDio().mockPostUriFailure<JsonMap>(
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
