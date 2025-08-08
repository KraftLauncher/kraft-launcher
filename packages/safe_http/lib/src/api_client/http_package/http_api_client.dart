import 'dart:convert' show jsonEncode;
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;
import 'package:json_utils/json_utils.dart' as json;
import 'package:result/result.dart';
import 'package:safe_http/src/api_client/api_client.dart';
import 'package:safe_http/src/api_client/api_failures.dart';
import 'package:safe_http/src/api_client/http_response.dart';
import 'package:safe_http/src/multipart/multipart_body.dart' show MultipartBody;

/// An implementation of [ApiClient] using [`package:http`](https://pub.dev/packages/http).
final class HttpApiClient implements ApiClient {
  HttpApiClient(this._client);

  final http.Client _client;

  @override
  JsonApiResultFuture<S, F> requestJson<S, F>(
    Uri url, {
    required HttpMethod method,
    Map<String, String>? headers,
    Object? body,
    bool isJsonBody = false,
    required JsonResponseDeserializer<S> deserializeSuccess,
    required JsonResponseDeserializer<F> deserializeFailure,
  }) async {
    final result = await _request(
      url,
      method: method,
      headers: _ensureJsonAcceptHeader(headers),
      body: body,
      isJsonBody: isJsonBody,
    );

    switch (result) {
      case SuccessResult<HttpResponse<String>, GeneralApiFailure<String>>():
        final response = result.value;

        final parseResult = json.tryJsonParse(
          response.body,
          (json) => deserializeSuccess(response._mapBody(json)),
        );

        switch (parseResult) {
          case SuccessResult<S, json.JsonParseFailure>():
            return Result.success(response._mapBody(parseResult.value));
          case FailureResult<S, json.JsonParseFailure>():
            return Result.failure(
              _mapJsonParseFailure(
                parseResult.failure,
                responseBody: response.body,
              ),
            );
        }

      case FailureResult<HttpResponse<String>, GeneralApiFailure<String>>():
        final failure = result.failure;

        switch (failure) {
          case HttpStatusFailure<String>(:final response):
            final responseBody = response.body;

            // This block shares some JSON decoding and deserialization failure handling
            // with the 2xx success case. While currently similar, the handling
            // may diverge further in the future, so the duplication is intentional
            // for clarity and separation of concerns.

            final parseResult = json.tryJsonParse(
              responseBody,
              (json) => deserializeFailure(response._mapBody(json)),
            );

            final mappedFailure = switch (parseResult) {
              SuccessResult<F, json.JsonParseFailure>(:final value) =>
                failure._mapBody((_) => value),
              FailureResult<F, json.JsonParseFailure>() =>
                _mapJsonParseFailure<F>(
                  parseResult.failure,
                  responseBody: responseBody,
                ),
            };
            return Result.failure(mappedFailure);

          case ConnectionFailure<String>():
            return Result.failure(ConnectionFailure<F>(failure.message));

          case UnknownFailure<String>():
            return Result.failure(UnknownFailure<F>(failure.message));
        }
    }
  }

  /// Maps a [json.JsonParseFailure] to a [JsonApiFailure]
  /// which is specific to [requestJson].
  JsonApiFailure<F> _mapJsonParseFailure<F>(
    json.JsonParseFailure failure, {
    required String responseBody,
  }) => switch (failure) {
    json.JsonDecodingFailure(:final reason) => JsonDecodingFailure<F>(
      responseBody,
      reason,
    ),
    json.JsonDeserializationFailure(:final decodedJson, :final reason) =>
      JsonDeserializationFailure<F>(decodedJson, reason),
  };

  @override
  StringApiResultFuture request(
    Uri url, {
    required HttpMethod method,
    Map<String, String>? headers,
    Object? body,
    bool isJsonBody = false,
  }) => _request(
    url,
    method: method,
    headers: headers,
    body: body,
    isJsonBody: isJsonBody,
  );

  Future<Result<HttpResponse<String>, GeneralApiFailure<String>>> _request(
    Uri url, {
    required HttpMethod method,
    required Map<String, String>? headers,
    required Object? body,
    required bool isJsonBody,
  }) async {
    _validateGetMethodHasNoBody(method: method, body: body);

    if (body is MultipartBody) {
      // Makes a multipart request

      _validateMultipartBodyIsNotJson(body: body, isJsonBody: isJsonBody);

      final MultipartBody multipartBody = body;

      return _mapExceptionsToFailure(() async {
        final response = await _sendMultipartRequest(
          method: method,
          url: url,
          body: multipartBody,
          headers: headers,
        );

        return _mapResponseToResult(response);
      });
    }

    // Makes a non-multipart request

    return _mapExceptionsToFailure(() async {
      final (preparedBody, preparedHeaders) = _encodeRequestBodyAsJsonIfNeeded(
        isJsonBody: isJsonBody,
        body: body,
        headers: headers,
      );

      final response = await _sendRequest(
        method: method,
        url: url,
        body: preparedBody,
        headers: preparedHeaders,
      );

      return _mapResponseToResult(response);
    });
  }

  /// Encodes [body] as JSON and adds the `Content-Type: application/json` header
  /// when [isJsonBody] is `true`.
  ///
  /// If [isJsonBody] is `true`, [body] must be a [json.JsonMap], otherwise an
  /// [ArgumentError] is thrown.
  ///
  /// Returns:
  ///
  /// * the encoded body and updated headers, when [isJsonBody] is `true` and [body] is a [json.JsonMap].
  /// * the original [body] and [headers] unchanged, when [isJsonBody] is `false`.
  (Object? body, Map<String, String>? headers)
  _encodeRequestBodyAsJsonIfNeeded({
    required Map<String, String>? headers,
    required Object? body,
    required bool isJsonBody,
  }) {
    if (!isJsonBody) {
      return (body, headers);
    }
    if (body is! json.JsonMap) {
      throw ArgumentError.value(body, 'body', 'must be a ${json.JsonMap}');
    }
    return (
      jsonEncode(body),
      {...?headers, 'Content-Type': 'application/json'},
    );
  }

  // TODO: REFACTORING_JSON_API_CLIENT Unit test for validating that we can't pass a non null body argument when method is get
  /// Throws an [ArgumentError] if [method] is [HttpMethod.get] and [body]
  /// is non-null.
  void _validateGetMethodHasNoBody({
    required HttpMethod method,
    required Object? body,
  }) {
    if (method == HttpMethod.get && body != null) {
      throw ArgumentError.value(
        body,
        'body',
        'must be null when when HTTP method is GET',
      );
    }
  }

  /// Throws an [ArgumentError] if [body] is [MultipartBody] and [isJsonBody]
  /// is `true`.
  void _validateMultipartBodyIsNotJson({
    required bool isJsonBody,
    required MultipartBody? body,
  }) {
    if (isJsonBody) {
      throw ArgumentError.value(
        body,
        'isJsonBody',
        'must be false when passing a $MultipartBody to the [body] argument',
      );
    }
  }

  /// Sends an HTTP request using `package:http`.
  ///
  /// Returns the response mapped to [_HttpResponse] to
  /// avoid using `package:http` types.
  Future<_HttpResponse> _sendRequest({
    required HttpMethod method,
    required Uri url,
    required Object? body,
    required Map<String, String>? headers,
  }) async {
    final response = await switch (method) {
      HttpMethod.get => _client.get(url, headers: headers),
      HttpMethod.post => _client.post(url, headers: headers, body: body),
    };
    return _mapHttpResponse(response);
  }

  /// Sends a multipart HTTP request using `package:http`.
  ///
  /// Returns the response mapped to [_HttpResponse] to
  /// avoid using `package:http` types.
  Future<_HttpResponse> _sendMultipartRequest({
    required HttpMethod method,
    required Uri url,
    required MultipartBody body,
    required Map<String, String>? headers,
  }) async {
    final httpMethodString = switch (method) {
      // This case is unreachable due to early validation in
      // _validateGetMethodHasNoBody(), which ensures [body] is null
      // for GET requests. If [body] is null, no [MultipartBody] was passed,
      // so this error will never be thrown.
      HttpMethod.get => throw UnsupportedError(
        'GET method does not support multipart requests. '
        'This error should not be thrown due to an early validation, '
        'this is likely an unexpected bug.',
      ),
      HttpMethod.post => 'POST',
    };
    final multipartRequest = http.MultipartRequest(httpMethodString, url)
      ..fields.addAll(body.fields)
      ..files.addAll(body.files);

    if (headers != null) {
      multipartRequest.headers.addAll(headers);
    }

    final streamedResponse = await _client.send(multipartRequest);
    final responseBody = await streamedResponse.stream.bytesToString();

    return _HttpResponse(
      body: responseBody,
      statusCode: streamedResponse.statusCode,
      headers: streamedResponse.headers,
      reasonPhrase: streamedResponse.reasonPhrase,
    );
  }

  Future<Result<S, GeneralApiFailure<F>>> _mapExceptionsToFailure<S, F>(
    Future<Result<S, GeneralApiFailure<F>>> Function() request,
  ) async {
    try {
      return await request();
    } on SocketException catch (e) {
      return Result.failure(ConnectionFailure(e.toString()));
    } on Exception catch (e) {
      // TODO: REFACTORING_JSON_API_CLIENT Unit test the new UnknownFailure, it's for unhandled expected errors now
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  Map<String, String> _ensureJsonAcceptHeader(Map<String, String>? headers) => {
    ...?headers,
    'Accept': 'application/json',
  };

  /// Converts a [http.Response] from `package:http` to internal [_HttpResponse].
  ///
  /// This decouples [_handleResponse] from external types,
  /// handling differences between [http.Response] and [http.StreamedResponse].
  ///
  /// Note: Multipart requests use [http.Client.send], which returns [http.StreamedResponse].
  /// We ignore differences with [http.Response] and [http.StreamedResponse]
  /// by mapping to [_HttpResponse] to keep decoupling.
  _HttpResponse _mapHttpResponse(http.Response response) => _HttpResponse(
    statusCode: response.statusCode,
    body: response.body,
    reasonPhrase: response.reasonPhrase,
    headers: response.headers,
  );

  Result<HttpResponse<T>, GeneralApiFailure<T>> _mapResponseToResult<T>(
    HttpResponse<T> response,
  ) {
    if (_isIn2xx(response.statusCode)) {
      return Result.success(response);
    }

    return Result.failure(HttpStatusFailure(response: response));
  }
}

/// Decouples internal code from external types,
/// handling differences between [http.Response] and [http.StreamedResponse].
///
/// Used internally in [HttpApiClient._handleResponse] avoid depending on
/// [http.Response] and for testing.
///
/// The [http.Client.post] method is required for making a Multipart request,
/// it returns a [http.StreamedResponse] rather than [http.Response].
typedef _HttpResponse = StringHttpResponse;

bool _isIn2xx(int statusCode) => statusCode >= 200 && statusCode < 300;

extension _MapResponse<T> on HttpResponse<T> {
  HttpResponse<R> _mapBody<R>(R newBody) {
    return HttpResponse<R>(
      body: newBody,
      statusCode: statusCode,
      headers: headers,
      reasonPhrase: reasonPhrase,
    );
  }
}

extension _MapApiFailure<T> on ApiFailure<T> {
  ApiFailure<R> _mapBody<R>(R Function(HttpResponse<T> oldResponse) transform) {
    final failure = this;
    if (failure case HttpStatusFailure<T>(:final response)) {
      final newBody = transform(response);
      final newResponse = response._mapBody<R>(newBody);
      return HttpStatusFailure<R>(response: newResponse);
    }
    // TODO: Probably does not work! need to recreate the instance
    return failure as ApiFailure<R>;
  }
}
