import 'dart:io' show SocketException;

import 'package:api_client/src/api_client.dart';
import 'package:api_client/src/api_failures.dart';
import 'package:api_client/src/http_package/_http_send_unstreamed.dart';
import 'package:api_client/src/http_response.dart';
import 'package:api_client/src/multipart/multipart_body.dart'
    show MultipartBody;
import 'package:api_client/src/request_body.dart';
import 'package:http/http.dart' as http;
import 'package:json_utils/json_utils.dart' as json;
import 'package:result/result.dart';

/// An implementation of [ApiClient] backed by [`package:http`](https://pub.dev/packages/http).
final class HttpApiClient implements ApiClient {
  HttpApiClient(this._client);

  final http.Client _client;

  @override
  Future<JsonApiResult<S, F>> requestJson<S, F>(
    Uri url, {
    required HttpMethod method,
    Map<String, String>? headers,
    RequestBody? body,
    required JsonResponseDeserializer<S> deserializeSuccess,
    required JsonResponseDeserializer<F> deserializeFailure,
  }) async {
    final result = await _request(
      url,
      method: method,
      headers: _ensureJsonAcceptHeader(headers),
      body: body,
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
                failure.mapResponse((_) => value),
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

  /// Maps a [json.JsonParseFailure] to a [JsonApiFailure],
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
  Future<StringApiResult> request(
    Uri url, {
    required HttpMethod method,
    Map<String, String>? headers,
    RequestBody? body,
  }) => _request(url, method: method, headers: headers, body: body);

  /// Performs an HTTP request for both multipart and regular bodies,
  /// encoding JSON if needed and mapping errors to [GeneralApiFailure].
  /// Used internally by [request] and [requestJson].
  Future<StringApiResult> _request(
    Uri url, {
    required HttpMethod method,
    required Map<String, String>? headers,
    required RequestBody? body,
  }) async {
    _validateMethodSupportsRequestBody(method: method, body: body);

    return _mapExceptionsToFailure(() async {
      final HttpResponse<String> response;

      if (body case MultipartRequestBody(:final multipart)) {
        // Sends a multipart request

        response = await _sendMultipartRequest(
          method: method,
          url: url,
          body: multipart,
          headers: headers,
        );
      } else {
        // Sends a non-multipart request

        final (preparedBody, preparedHeaders) =
            _encodeRequestBodyAsJsonIfNeeded(body: body, headers: headers);

        response = await _sendRequest(
          method: method,
          url: url,
          body: preparedBody,
          headers: preparedHeaders,
        );
      }

      return _mapResponseToResult(response);
    });
  }

  /// Encodes the request body as JSON and adds the `Content-Type: application/json` header
  /// when [body] is a [JsonRequestBody].
  ///
  /// Returns:
  ///
  /// * the encoded body and updated headers, when [body] is a [JsonRequestBody].
  /// * the original [headers] and raw value of [RawRequestBody], when [body] is a [RawRequestBody].
  (Object? body, Map<String, String>? headers)
  _encodeRequestBodyAsJsonIfNeeded({
    required Map<String, String>? headers,
    required RequestBody? body,
  }) {
    return switch (body) {
      null => (null, headers),
      JsonRequestBody() => (
        json.jsonEncode(body.json),
        {...?headers, 'Content-Type': 'application/json'},
      ),
      MultipartRequestBody() => throw UnsupportedError(
        'The internal method $HttpApiClient._encodeRequestBodyAsJsonIfNeeded() must '
        'not be called internally when the body argument is a $MultipartRequestBody. '
        'This utility function is not meant to be used for multipart requests.',
      ),
      RawRequestBody() => (body.raw, headers),
    };
  }

  /// Throws an [ArgumentError] if [body] is non-null and [method] does not
  /// support a request body (e.g., GET or other methods without body support).
  void _validateMethodSupportsRequestBody({
    required HttpMethod method,
    required Object? body,
  }) {
    if (body != null && !method.supportsRequestBody) {
      throw ArgumentError.value(
        body,
        'body',
        'must be null when HTTP method is ${method.httpName}',
      );
    }
  }

  /// Sends an HTTP request using `package:http`.
  ///
  /// Returns the response mapped to [_HttpResponse] to
  /// avoid using `package:http` types.
  ///
  /// See also the internal extension: [SendUnstreamedInternal]
  Future<_HttpResponse> _sendRequest({
    required HttpMethod method,
    required Uri url,
    required Object? body,
    required Map<String, String>? headers,
  }) async {
    if (body is RequestBody) {
      // Internal callers should avoid passing a RequestBody to this method.
      throw ArgumentError.value(body, 'body', 'must not be a $RequestBody');
    }

    final httpMethodString = _httpMethodAsString(method);
    final response = await _client.sendUnstreamed(
      httpMethodString,
      url,
      headers,
      body,
    );
    return _mapHttpResponse(response);
  }

  /// Sends a multipart HTTP request using `package:http`.
  ///
  /// Returns the response mapped to [_HttpResponse] to
  /// avoid using `package:http` types.
  ///
  /// Note: This method will never be called with a [method] that does
  /// not support a request body, due to early validation in
  /// [_validateMethodSupportsRequestBody], which ensures [body] is null for
  /// methods where [HttpMethod.supportsRequestBody] is `false`. Therefore, methods
  /// like GET that do not support a request body will never reach this code,
  /// and no [MultipartBody] will be passed for them.
  Future<_HttpResponse> _sendMultipartRequest({
    required HttpMethod method,
    required Uri url,
    required MultipartBody body,
    required Map<String, String>? headers,
  }) async {
    final httpMethodString = _httpMethodAsString(method);
    final multipartRequest = http.MultipartRequest(httpMethodString, url)
      ..fields.addAll(body.fields)
      ..files.addAll(body.files);

    if (headers != null) {
      multipartRequest.headers.addAll(headers);
    }

    final streamedResponse = await _client.send(multipartRequest);
    final response = await http.Response.fromStream(streamedResponse);

    return _mapHttpResponse(response);
  }

  /// Returns the HTTP method name as a [String] that can be used
  /// with [http.MultipartRequest] or [http.Request] from `package:http`.
  ///
  /// This matches the HTTP method names with internal `package:http` code:
  /// https://github.com/dart-lang/http/blob/6656f15e88e68f6cafa2a7bbffa37fd6ac2dd33a/pkgs/http/lib/src/base_client.dart#L21-L47
  //
  /// We intentionally avoid using `method.name.toUpperCase()` because
  /// that would couple the [HttpMethod] enum names to `package:http` implementation.
  /// Renaming an enum value could then introduce a regression.
  String _httpMethodAsString(HttpMethod method) => switch (method) {
    HttpMethod.get => 'GET',
    HttpMethod.post => 'POST',
    HttpMethod.put => 'PUT',
    HttpMethod.patch => 'PATCH',
    HttpMethod.delete => 'DELETE',
  };

  Future<Result<S, GeneralApiFailure<F>>> _mapExceptionsToFailure<S, F>(
    Future<Result<S, GeneralApiFailure<F>>> Function() request,
  ) async {
    try {
      return await request();
    } on SocketException catch (e) {
      // See also: https://github.com/dart-lang/http/blob/6656f15e88e68f6cafa2a7bbffa37fd6ac2dd33a/pkgs/http/lib/src/io_client.dart#L22-L27
      return Result.failure(ConnectionFailure(e.toString()));
    } on Exception catch (e) {
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
  /// Note: Requests always use [http.Client.send] rather than high-level methods
  /// such as [http.Client.get] or [http.Client.post], which returns [http.StreamedResponse].
  /// We ignore differences with [http.Response] and [http.StreamedResponse]
  /// by mapping to internal [_HttpResponse] to keep decoupling.
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
/// Used internally avoid depending on [http.Response] and [http.StreamedResponse].
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

extension _HttpStatusFailureMapper<T> on HttpStatusFailure<T> {
  ApiFailure<R> mapResponse<R>(
    R Function(HttpResponse<T> oldResponse) transform,
  ) {
    final newBody = transform(response);
    final newResponse = response._mapBody<R>(newBody);
    return HttpStatusFailure<R>(response: newResponse);
  }
}
