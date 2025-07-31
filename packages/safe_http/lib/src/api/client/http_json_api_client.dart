import 'dart:io' show HttpHeaders, HttpStatus, SocketException;

import 'package:http/http.dart' as http;
import 'package:json_utils/json_utils.dart' as json;
import 'package:result/result.dart';
import 'package:safe_http/safe_http.dart';
import 'package:safe_http/src/api/client/json_api_client.dart';
import 'package:safe_http/src/http_status_code.dart';

final class HttpJsonApiClient implements JsonApiClient {
  HttpJsonApiClient(this._client);

  final http.Client _client;

  @override
  JsonApiResult<Response, ClientError> get<Response, ClientError>(
    Uri url, {
    Map<String, String>? headers,
    required JsonResponseDeserializer<Response> deserializeSuccess,
    required JsonResponseDeserializer<ClientError> deserializeClientFailure,
  }) async {
    return _handleFailures(() async {
      final response = await _client.get(url, headers: headers);
      return _handleResponse(
        response,
        deserializeSuccess: deserializeSuccess,
        deserializeClientFailure: deserializeClientFailure,
      );
    });
  }

  @override
  JsonApiResult<Response, ClientError> post<Response, ClientError>(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    required JsonResponseDeserializer<Response> deserializeSuccess,
    required JsonResponseDeserializer<ClientError> deserializeClientFailure,
  }) async {
    return _handleFailures(() async {
      final response = await _client.post(url, headers: headers, body: body);
      return _handleResponse(
        response,
        deserializeSuccess: deserializeSuccess,
        deserializeClientFailure: deserializeClientFailure,
      );
    });
  }

  JsonApiResult<Response, ClientError> _handleFailures<Response, ClientError>(
    JsonApiResult<Response, ClientError> Function() request,
  ) async {
    try {
      return await request();
    } on SocketException catch (e) {
      return Result.failure(ConnectionFailure(e.toString()));
    }
  }

  JsonApiResult<Response, ClientError> _handleResponse<Response, ClientError>(
    http.Response response, {
    required JsonResponseDeserializer<Response> deserializeSuccess,
    required JsonResponseDeserializer<ClientError> deserializeClientFailure,
  }) async {
    final statusCode = response.statusCode;
    final responseBody = response.body;

    final isSuccess = isIn2xx(statusCode);

    if (isSuccess) {
      final jsonDecodeResult = json.tryJsonDecode(responseBody);

      final decoded = jsonDecodeResult.valueOrNull;
      if (decoded == null) {
        return Result.failure(
          JsonDecodingFailure(
            responseBody,
            jsonDecodeResult.failureOrThrow.reason,
          ),
        );
      }

      final jsonDeserializationResult = json.tryJsonDeserialize(
        decoded,
        (decoded) => deserializeSuccess(decoded, statusCode),
      );

      final deserialized = jsonDeserializationResult.valueOrNull;

      if (deserialized == null) {
        return Result.failure(
          JsonDeserializationFailure(
            decoded,
            jsonDeserializationResult.failureOrThrow.reason,
          ),
        );
      }

      return Result.success(deserialized);
    }

    // It's important to handle 429 (too many requests)
    // before checking if code is in 4xx to avoid a regression.
    if (statusCode == HttpStatus.tooManyRequests) {
      return Result.failure(const TooManyRequestsFailure());
    }

    final isClientError = isIn4xx(statusCode);
    if (isClientError) {
      // This block shares some JSON decoding and deserialization failure handling
      // with the 2xx success case. While currently similar, the handling
      // may diverge further in the future, so the duplication is intentional
      // for clarity and separation of concerns.

      final jsonDecodeResult = json.tryJsonDecode(responseBody);

      final decoded = jsonDecodeResult.valueOrNull;
      if (decoded == null) {
        return Result.failure(
          JsonDecodingFailure(
            responseBody,
            jsonDecodeResult.failureOrThrow.reason,
          ),
        );
      }

      final jsonDeserializationResult = json.tryJsonDeserialize(
        decoded,
        (decoded) => deserializeClientFailure(decoded, statusCode),
      );

      final deserialized = jsonDeserializationResult.valueOrNull;

      if (deserialized == null) {
        return Result.failure(
          JsonDeserializationFailure(
            decoded,
            jsonDeserializationResult.failureOrThrow.reason,
          ),
        );
      }

      return Result.failure(
        ClientResponseFailure<ClientError>(
          statusCode: statusCode,
          reasonPhrase: response.reasonPhrase,
          responseBody: deserialized,
          headers: response.headers,
        ),
      );
    }

    // It's important to handle 503 (service unavailable)
    // before checking if code is in 5xx to avoid a regression.
    if (statusCode == HttpStatus.serviceUnavailable) {
      final retryAfter = response.headers[HttpHeaders.retryAfterHeader];
      return Result.failure(
        ServiceUnavailableFailure(
          retryAfterInSeconds: retryAfter != null
              ? int.tryParse(retryAfter)
              : null,
        ),
      );
    }

    final isServerError = isIn5xx(statusCode);
    if (isServerError) {
      return Result.failure(
        InternalServerFailure(
          responseBody: responseBody,
          statusCode: statusCode,
        ),
      );
    }

    return Result.failure(
      UnknownFailure(
        'Unknown or unhandled HTTP error ($statusCode): $responseBody',
        statusCode: response.statusCode,
        responseBody: responseBody,
      ),
    );
  }
}
