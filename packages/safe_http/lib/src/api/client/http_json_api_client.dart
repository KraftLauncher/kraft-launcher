import 'dart:convert' show jsonEncode;
import 'dart:io' show HttpHeaders, HttpStatus, SocketException;

import 'package:http/http.dart' as http;
import 'package:json_utils/json_utils.dart' as json;
import 'package:result/result.dart';
import 'package:safe_http/src/api/api_failures.dart';
import 'package:safe_http/src/api/client/json_api_client.dart';
import 'package:safe_http/src/http_status_code.dart';

final class HttpJsonApiClient implements JsonApiClient {
  HttpJsonApiClient(this._client);

  final http.Client _client;

  @override
  JsonApiResultFuture<S, C> get<S, C>(
    Uri url, {
    Map<String, String>? headers,
    required JsonResponseDeserializer<S> deserializeSuccess,
    required JsonResponseDeserializer<C> deserializeClientFailure,
  }) async {
    return _handleSocketException(() async {
      final response = await _client.get(
        url,
        headers: _ensureJsonAcceptHeader(headers),
      );
      return _handleResponse(
        response,
        deserializeSuccess: deserializeSuccess,
        deserializeClientFailure: deserializeClientFailure,
      );
    });
  }

  @override
  JsonApiResultFuture<S, C> post<S, C>(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    bool isJsonBody = false,
    required JsonResponseDeserializer<S> deserializeSuccess,
    required JsonResponseDeserializer<C> deserializeClientFailure,
  }) async {
    if (isJsonBody) {
      if (body is! json.JsonMap) {
        throw ArgumentError.value(body, 'body', 'must be a ${json.JsonMap}');
      }
      body = jsonEncode(body);
      headers = {...?headers, 'Content-Type': 'application/json'};
    }

    return _handleSocketException(() async {
      final response = await _client.post(
        url,
        headers: _ensureJsonAcceptHeader(headers),
        body: body,
      );
      return _handleResponse(
        response,
        deserializeSuccess: deserializeSuccess,
        deserializeClientFailure: deserializeClientFailure,
      );
    });
  }

  JsonApiResultFuture<S, C> _handleSocketException<S, C>(
    JsonApiResultFuture<S, C> Function() request,
  ) async {
    try {
      return await request();
    } on SocketException catch (e) {
      return Result.failure(ConnectionFailure(e.toString()));
    }
  }

  Map<String, String> _ensureJsonAcceptHeader(Map<String, String>? headers) => {
    ...?headers,
    'Accept': 'application/json',
  };

  JsonApiResultFuture<S, C> _handleResponse<S, C>(
    http.Response response, {
    required JsonResponseDeserializer<S> deserializeSuccess,
    required JsonResponseDeserializer<C> deserializeClientFailure,
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
        (decoded) => deserializeSuccess(
          JsonResponse(json: decoded, statusCode: statusCode),
        ),
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
        (decoded) => deserializeClientFailure(
          JsonResponse(json: decoded, statusCode: statusCode),
        ),
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
        ClientResponseFailure<C>(
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
