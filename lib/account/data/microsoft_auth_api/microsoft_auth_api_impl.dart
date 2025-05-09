import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';

import '../../../common/constants/microsoft_constants.dart';
import '../../../common/logic/dio_client.dart';
import '../../../common/logic/json.dart';
import 'auth_methods/microsoft_device_code_flow.dart';
import 'microsoft_auth_api.dart';
import 'microsoft_auth_exceptions.dart';

class MicrosoftAuthApiImpl implements MicrosoftAuthApi {
  MicrosoftAuthApiImpl({required this.dio});

  final Dio dio;

  Future<T> _handleCommonFailures<T>(
    Future<T> Function() run, {
    T? Function(DioException e)? customHandle,
  }) async {
    try {
      return await run();
    } on DioException catch (e, stackTrace) {
      final customHandleResult = customHandle?.call(e);
      if (customHandleResult != null) {
        return customHandleResult;
      }

      if (e.response?.statusCode == HttpStatus.tooManyRequests) {
        throw MicrosoftAuthException.tooManyRequests();
      }

      // The error code and description are included in responses of requests
      // that made to Microsoft, and not Xbox. Xbox APIs usually returns error details in the headers
      // and additionally in the response data (XErr) when requesting XSTS. It's handled
      // in requestXboxLiveToken() and requestXSTSToken().
      final errorBody = e.response?.data as JsonObject?;
      final code = errorBody?['error'] as String?;
      final errorDescription = errorBody?['error_description'] as String?;

      final exception = switch (code) {
        String() => MicrosoftAuthException.unknown(
          'Code: $code, Details: ${errorDescription ?? 'The error description is not provided.'}',
          stackTrace,
        ),
        null => MicrosoftAuthException.unknown(
          'The error code is not provided: ${e.response?.data}, ${e.response?.headers}',
          stackTrace,
        ),
      };
      throw exception;
    } on Exception catch (e, stackTrace) {
      throw MicrosoftAuthException.unknown(e.toString(), stackTrace);
    }
  }

  // START: Auth code

  @override
  String userLoginUrlWithAuthCode() =>
      Uri.https('login.live.com', '/oauth20_authorize.srf', {
        'client_id': MicrosoftConstants.loginClientId,
        'response_type': 'code',
        'redirect_uri': MicrosoftConstants.loginRedirectUrl,
        'scope': MicrosoftConstants.loginScopes,
      }).toString();

  @override
  Future<MicrosoftOauthTokenExchangeResponse> exchangeAuthCodeForTokens(
    String authCode,
  ) async => _handleCommonFailures(
    () async {
      final response = await dio.postUri<JsonObject>(
        Uri.https('login.live.com', '/oauth20_token.srf'),
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
        data: {
          'client_id': MicrosoftConstants.loginClientId,
          'grant_type': 'authorization_code',
          'code': authCode,
          'redirect_uri': MicrosoftConstants.loginRedirectUrl,
          'scope': MicrosoftConstants.loginScopes,
        },
      );

      return MicrosoftOauthTokenExchangeResponse.fromJson(response.dataOrThrow);
    },
    customHandle: (e) {
      final errorBody = e.response?.data as JsonObject?;
      final code = errorBody?['error'] as String?;
      if (code == 'invalid_grant') {
        throw MicrosoftAuthException.authCodeExpired();
      }
      return null;
    },
  );

  // END: Auth code

  // START: Device code

  @override
  Future<MicrosoftRequestDeviceCodeResponse> requestDeviceCode() =>
      _handleCommonFailures(() async {
        final response = await dio.postUri<JsonObject>(
          Uri.https(
            'login.microsoftonline.com',
            '/consumers/oauth2/v2.0/devicecode',
          ),
          options: Options(
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          ),
          data: {
            'client_id': MicrosoftConstants.loginClientId,
            'scope': MicrosoftConstants.loginScopes,
          },
        );
        return MicrosoftRequestDeviceCodeResponse.fromJson(
          response.dataOrThrow,
        );
      });

  @override
  Future<MicrosoftCheckDeviceCodeStatusResult> checkDeviceCodeStatus(
    MicrosoftRequestDeviceCodeResponse deviceCodeResponse,
  ) => _handleCommonFailures(
    () async {
      final response = await dio.postUri<JsonObject>(
        Uri.https('login.microsoftonline.com', '/consumers/oauth2/v2.0/token'),
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
        data: {
          'client_id': MicrosoftConstants.loginClientId,
          'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
          'device_code': deviceCodeResponse.deviceCode,
        },
      );

      return MicrosoftDeviceCodeSuccess(
        response: MicrosoftOauthTokenExchangeResponse.fromJson(
          response.dataOrThrow,
        ),
      );
    },
    customHandle: (e) {
      final errorBody = e.response?.data as JsonObject?;
      final code = errorBody?['error'] as String?;
      if (code == 'authorization_pending') {
        return const MicrosoftDeviceCodeAuthorizationPending();
      }
      if (code == 'expired_token') {
        return const MicrosoftDeviceCodeExpired();
      }

      return null;
    },
  );

  // END: Device code

  // START: Xbox

  @override
  Future<XboxLiveAuthTokenResponse> requestXboxLiveToken(
    // The error code and description are included in responses of requests
    // that made to Microsoft, and not Xbox. Xbox APIs usually returns error details in the headers
    // and additionally in the response data (XErr) when requesting XSTS. It's handled
    // in requestXboxLiveToken and requestXSTSToken.
    MicrosoftOauthTokenExchangeResponse microsoftOauthToken,
  ) async => _handleCommonFailures(
    () async {
      final response = await dio.postUri<JsonObject>(
        Uri.https('user.auth.xboxlive.com', '/user/authenticate'),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
        data: {
          'Properties': {
            'AuthMethod': 'RPS',
            'SiteName': 'user.auth.xboxlive.com',
            'RpsTicket': 'd=${microsoftOauthToken.accessToken}',
          },
          'RelyingParty': 'http://auth.xboxlive.com',
          'TokenType': 'JWT',
        },
      );
      return XboxLiveAuthTokenResponse.fromJson(response.dataOrThrow);
    },
    customHandle: (e) {
      final headers = e.response?.headers;
      if (headers != null && !headers.isEmpty) {
        final wwwAuthenticateHeader = headers['Www-Authenticate']?.firstOrNull;

        // This header is usually 'XASU error=token_expired' when expired.
        if (wwwAuthenticateHeader?.contains('token_expired') ?? false) {
          // The request body is empty in case of a failure.
          throw MicrosoftAuthException.xboxTokenRequestFailedDueToExpiredAccessToken();
        }
      }
      return null;
    },
  );

  @override
  Future<XboxLiveAuthTokenResponse> requestXSTSToken(
    XboxLiveAuthTokenResponse xboxLiveToken,
  ) => _handleCommonFailures(
    () async {
      final response = await dio.postUri<JsonObject>(
        Uri.https('xsts.auth.xboxlive.com', '/xsts/authorize'),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
        data: {
          'Properties': {
            'SandboxId': 'RETAIL',
            'UserTokens': [xboxLiveToken.xboxToken],
          },
          'RelyingParty': 'rp://api.minecraftservices.com/',
          'TokenType': 'JWT',
        },
      );
      return XboxLiveAuthTokenResponse.fromJson(response.dataOrThrow);
    },
    customHandle: (e) {
      final errorBody = e.response?.data as JsonObject?;
      final message = errorBody?['Message'] as String?;
      final xErr = errorBody?['XErr'] as int?;
      final xstsError =
          xErr != null
              ? XstsError.values.firstWhereOrNull((e) => e.xErr == xErr)
              : null;

      if (e.response?.statusCode != HttpStatus.unauthorized &&
          xErr == null &&
          message == null) {
        return null;
      }

      throw MicrosoftAuthException.xstsError(
        message ??
            'An unknown error, Xbox API did not provided a message, headers: ${e.response?.headers}',
        xErr: xErr,
        xstsError: xstsError,
      );
    },
  );

  // START: Xbox

  @override
  Future<MicrosoftOauthTokenExchangeResponse> getNewTokensFromRefreshToken(
    String microsoftRefreshToken,
  ) => _handleCommonFailures(
    () async {
      final response = await dio.postUri<JsonObject>(
        Uri.https('login.live.com', '/oauth20_token.srf'),
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
        data: {
          'client_id': MicrosoftConstants.loginClientId,
          'grant_type': 'refresh_token',
          'refresh_token': microsoftRefreshToken,
        },
      );

      return MicrosoftOauthTokenExchangeResponse.fromJson(response.dataOrThrow);
    },
    customHandle: (e) {
      final errorBody = e.response?.data as JsonObject?;
      final code = errorBody?['error'] as String?;
      if (code == 'invalid_grant') {
        throw MicrosoftAuthException.expiredOrUnauthorizedMicrosoftRefreshToken();
      }
      return null;
    },
  );
}
