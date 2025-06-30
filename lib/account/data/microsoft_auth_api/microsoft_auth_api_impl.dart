import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:kraft_launcher/account/data/microsoft_auth_api/auth_flows/microsoft_device_code_flow_api.dart';
import 'package:kraft_launcher/account/data/microsoft_auth_api/microsoft_auth_api.dart';
import 'package:kraft_launcher/account/data/microsoft_auth_api/microsoft_auth_api_exceptions.dart'
    as microsoft_auth_api_exceptions;
import 'package:kraft_launcher/common/constants/constants.dart';
import 'package:kraft_launcher/common/constants/project_info_constants.dart';
import 'package:kraft_launcher/common/logic/dio_client.dart';
import 'package:kraft_launcher/common/logic/json.dart';

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
        throw const microsoft_auth_api_exceptions.TooManyRequestsException();
      }

      // The error code and description are included in responses of requests
      // that made to Microsoft, and not Xbox. Xbox APIs usually returns error details in the headers
      // and additionally in the response data (XErr) when requesting XSTS. It's handled
      // in requestXboxLiveToken() and requestXSTSToken().
      final errorBody = e.response?.data as JsonMap?;
      final code = errorBody?['error'] as String?;
      final errorDescription = errorBody?['error_description'] as String?;

      final exception = switch (code) {
        String() => microsoft_auth_api_exceptions.UnknownException(
          'Code: $code, Details: ${errorDescription ?? 'The error description is not provided.'}',
          stackTrace,
        ),
        null => microsoft_auth_api_exceptions.UnknownException(
          'The error code is not provided: ${e.response?.data}, ${e.response?.headers}',
          stackTrace,
        ),
      };
      throw exception;
    } on Exception catch (e, stackTrace) {
      throw microsoft_auth_api_exceptions.UnknownException(
        e.toString(),
        stackTrace,
      );
    }
  }

  // START: Auth code

  @override
  String userLoginUrlWithAuthCode() =>
      Uri.https('login.live.com', '/oauth20_authorize.srf', {
        'client_id': ProjectInfoConstants.microsoftLoginClientId,
        'response_type': 'code',
        'redirect_uri': MicrosoftConstants.loginRedirectUrl,
        'scope': MicrosoftConstants.loginScopes,
      }).toString();

  @override
  Future<MicrosoftOAuthTokenResponse> exchangeAuthCodeForTokens(
    String authCode,
  ) async => _handleCommonFailures(
    () async {
      final response = await dio.postUri<JsonMap>(
        Uri.https('login.live.com', '/oauth20_token.srf'),
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
        data: {
          'client_id': ProjectInfoConstants.microsoftLoginClientId,
          'grant_type': 'authorization_code',
          'code': authCode,
          'redirect_uri': MicrosoftConstants.loginRedirectUrl,
          'scope': MicrosoftConstants.loginScopes,
        },
      );

      return MicrosoftOAuthTokenResponse.fromJson(response.dataOrThrow);
    },
    customHandle: (e) {
      final errorBody = e.response?.data as JsonMap?;
      final code = errorBody?['error'] as String?;
      if (code == 'invalid_grant') {
        throw const microsoft_auth_api_exceptions.AuthCodeExpiredException();
      }
      return null;
    },
  );

  // END: Auth code

  // START: Device code

  @override
  Future<MicrosoftRequestDeviceCodeResponse> requestDeviceCode() =>
      _handleCommonFailures(() async {
        final response = await dio.postUri<JsonMap>(
          Uri.https(
            'login.microsoftonline.com',
            '/consumers/oauth2/v2.0/devicecode',
          ),
          options: Options(
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          ),
          data: {
            'client_id': ProjectInfoConstants.microsoftLoginClientId,
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
      final response = await dio.postUri<JsonMap>(
        Uri.https('login.microsoftonline.com', '/consumers/oauth2/v2.0/token'),
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
        data: {
          'client_id': ProjectInfoConstants.microsoftLoginClientId,
          'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
          'device_code': deviceCodeResponse.deviceCode,
        },
      );

      return MicrosoftCheckDeviceCodeStatusResult.approved(
        MicrosoftOAuthTokenResponse.fromJson(response.dataOrThrow),
      );
    },
    customHandle: (e) {
      final errorBody = e.response?.data as JsonMap?;
      final code = errorBody?['error'] as String?;
      if (code == 'authorization_pending') {
        return MicrosoftCheckDeviceCodeStatusResult.authorizationPending();
      }
      if (code == 'expired_token') {
        return MicrosoftCheckDeviceCodeStatusResult.expired();
      }
      if (code == 'authorization_declined') {
        return MicrosoftCheckDeviceCodeStatusResult.declined();
      }

      return null;
    },
  );

  // END: Device code

  // START: Xbox

  @override
  Future<XboxLiveAuthTokenResponse> requestXboxLiveToken(
    String microsoftAccessToken,
  ) async => _handleCommonFailures(
    () async {
      final response = await dio.postUri<JsonMap>(
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
            'RpsTicket': 'd=$microsoftAccessToken',
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
          throw const microsoft_auth_api_exceptions.XboxTokenMicrosoftAccessTokenExpiredException();
        }
      }
      return null;
    },
  );

  @override
  Future<XboxLiveAuthTokenResponse> requestXSTSToken(
    String xboxLiveToken,
  ) => _handleCommonFailures(
    () async {
      final response = await dio.postUri<JsonMap>(
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
            'UserTokens': [xboxLiveToken],
          },
          'RelyingParty': 'rp://api.minecraftservices.com/',
          'TokenType': 'JWT',
        },
      );
      return XboxLiveAuthTokenResponse.fromJson(response.dataOrThrow);
    },
    customHandle: (e) {
      final errorBody = e.response?.data as JsonMap?;
      final message = errorBody?['Message'] as String?;
      final xErr = errorBody?['XErr'] as int?;
      final xstsError =
          xErr != null
              ? microsoft_auth_api_exceptions.XstsError.values.firstWhereOrNull(
                (e) => e.xErr == xErr,
              )
              : null;

      if (e.response?.statusCode != HttpStatus.unauthorized &&
          xErr == null &&
          message == null) {
        return null;
      }

      throw microsoft_auth_api_exceptions.XstsErrorException(
        message ??
            'An unknown error, Xbox API did not provided a message, headers: ${e.response?.headers}',
        xErr: xErr,
        xstsError: xstsError,
      );
    },
  );

  // END: Xbox

  @override
  Future<MicrosoftOAuthTokenResponse> getNewTokensFromRefreshToken(
    String microsoftRefreshToken,
  ) => _handleCommonFailures(
    () async {
      final response = await dio.postUri<JsonMap>(
        Uri.https('login.live.com', '/oauth20_token.srf'),
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
        data: {
          'client_id': ProjectInfoConstants.microsoftLoginClientId,
          'grant_type': 'refresh_token',
          'refresh_token': microsoftRefreshToken,
        },
      );

      return MicrosoftOAuthTokenResponse.fromJson(response.dataOrThrow);
    },
    customHandle: (e) {
      final errorBody = e.response?.data as JsonMap?;
      final code = errorBody?['error'] as String?;
      if (code == 'invalid_grant') {
        throw const microsoft_auth_api_exceptions.InvalidRefreshTokenException();
      }
      return null;
    },
  );
}
