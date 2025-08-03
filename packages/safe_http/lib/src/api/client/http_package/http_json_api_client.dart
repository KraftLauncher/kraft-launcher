import 'dart:convert' show jsonEncode;
import 'dart:io' show HttpHeaders, HttpStatus, SocketException;

import 'package:http/http.dart' as http;
import 'package:json_utils/json_utils.dart' as json;
import 'package:meta/meta.dart';
import 'package:result/result.dart';
import 'package:safe_http/src/api/api_failures.dart';
import 'package:safe_http/src/api/client/json_api_client.dart';
import 'package:safe_http/src/http_status_utils.dart';
import 'package:safe_http/src/multipart/multipart_body.dart' show MultipartBody;

/// An implementation of [JsonApiClient] using [`package:http`](https://pub.dev/packages/http).
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
        response: _mapHttpResponse(response),
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
    if (body is MultipartBody) {
      if (isJsonBody) {
        // Makes a multipart request using http.Client.send()
        throw ArgumentError.value(
          body,
          'isJsonBody',
          'must be false when passing a $MultipartBody to the [body] argument',
        );
      }

      final MultipartBody multipartBody = body;

      return _handleSocketException(() async {
        final response = await _sendMultipartRequest(
          method: 'POST',
          url: url,
          body: multipartBody,
          headers: _ensureJsonAcceptHeader(headers),
        );
        return _handleResponse(
          response: response,
          deserializeSuccess: deserializeSuccess,
          deserializeClientFailure: deserializeClientFailure,
        );
      });
    }

    // Makes a non-multipart request using http.Client.post()

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
        response: _mapHttpResponse(response),
        deserializeSuccess: deserializeSuccess,
        deserializeClientFailure: deserializeClientFailure,
      );
    });
  }

  Future<HttpResponse> _sendMultipartRequest({
    required String method,
    required Uri url,
    required MultipartBody body,
    required Map<String, String> headers,
  }) async {
    final multipartRequest = http.MultipartRequest(method, url)
      ..fields.addAll(body.fields)
      ..files.addAll(body.files)
      ..headers.addAll(headers);

    final streamedResponse = await _client.send(multipartRequest);
    final responseBody = await streamedResponse.stream.bytesToString();

    return HttpResponse(
      body: responseBody,
      statusCode: streamedResponse.statusCode,
      headers: streamedResponse.headers,
      reasonPhrase: streamedResponse.reasonPhrase,
    );
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

  /// Converts a [http.Response] from `package:http` to internal [HttpResponse].
  ///
  /// This decouples [_handleResponse] from external types,
  /// handling differences between [http.Response] and [http.StreamedResponse].
  ///
  /// Note: Multipart requests use [http.Client.send], which returns [http.StreamedResponse].
  /// We ignore differences with [http.Response] and [http.StreamedResponse]
  /// by mapping to [HttpResponse] to keep decoupling.
  HttpResponse _mapHttpResponse(http.Response response) => HttpResponse(
    statusCode: response.statusCode,
    body: response.body,
    reasonPhrase: response.reasonPhrase,
    headers: response.headers,
  );

  JsonApiResultFuture<S, C> _handleResponse<S, C>({
    required HttpResponse response,
    required JsonResponseDeserializer<S> deserializeSuccess,
    required JsonResponseDeserializer<C> deserializeClientFailure,
  }) async {
    final (responseBody, statusCode, headers, reasonPhrase) = (
      response.body,
      response.statusCode,
      response.headers,
      response.reasonPhrase,
    );

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
          JsonHttpResponse(body: decoded, statusCode: statusCode),
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
          JsonHttpResponse(body: decoded, statusCode: statusCode),
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
          reasonPhrase: reasonPhrase,
          responseBody: deserialized,
          headers: headers,
        ),
      );
    }

    // It's important to handle 503 (service unavailable)
    // before checking if code is in 5xx to avoid a regression.
    if (statusCode == HttpStatus.serviceUnavailable) {
      final retryAfter = headers[HttpHeaders.retryAfterHeader];
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
        statusCode: statusCode,
        responseBody: responseBody,
      ),
    );
  }
}

/// Decouples internal code from external types,
/// handling differences between [http.Response] and [http.StreamedResponse].
///
/// Used internally in [HttpJsonApiClient._handleResponse] avoid depending on
/// [http.Response] and for testing.
///
/// The [http.Client.post] method is required for making a Multipart request,
/// it returns a [http.StreamedResponse] rather than [http.Response].
@visibleForTesting
@internal
@immutable
class HttpResponse {
  const HttpResponse({
    required this.statusCode,
    required this.body,
    required this.reasonPhrase,
    required this.headers,
  });

  final int statusCode;
  final String body;
  final String? reasonPhrase;
  final Map<String, String> headers;
}
