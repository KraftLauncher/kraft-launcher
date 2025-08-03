import 'dart:convert' show jsonDecode, jsonEncode, utf8;
import 'dart:io' show HttpHeaders, HttpStatus, SocketException;

import 'package:http/http.dart' as http;
import 'package:json_utils/json_utils.dart' show JsonMap;
import 'package:meta/meta.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result/result.dart';
import 'package:safe_http/src/api/api_failures.dart';
import 'package:safe_http/src/api/client/http_package/http_json_api_client.dart';
import 'package:safe_http/src/api/client/json_api_client.dart';
import 'package:safe_http/src/multipart/multipart_body.dart';
import 'package:test/test.dart';

void main() {
  late _MockHttpClient mockHttpClient;
  late JsonApiClient client;

  void mockGet(Future<HttpResponse> Function() getHttpResponse) =>
      when(
        () => mockHttpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => _mapHttpResponseToResponse(await getHttpResponse()),
      );

  void mockPost(Future<HttpResponse> Function() getHttpResponse) =>
      when(
        () => mockHttpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
          encoding: any(named: 'encoding'),
        ),
      ).thenAnswer(
        (_) async => _mapHttpResponseToResponse(await getHttpResponse()),
      );

  void mockSend(Future<HttpResponse> Function() getHttpResponse) =>
      when(() => mockHttpClient.send(any())).thenAnswer(
        (_) async =>
            _mapHttpResponseToStreamedResponse(await getHttpResponse()),
      );

  setUp(() {
    mockHttpClient = _MockHttpClient();

    client = HttpJsonApiClient(mockHttpClient);
  });

  setUpAll(() {
    registerFallbackValue(Uri());
    registerFallbackValue(_FakeBaseRequest());
  });

  group('get', () {
    setUp(() {
      mockGet(() async => _dummyResponse);
    });

    JsonApiResultFuture<S, C> get<S, C>(
      Uri? url, {
      Map<String, String>? headers,
      JsonResponseDeserializer<S>? deserializeSuccess,
      JsonResponseDeserializer<C>? deserializeClientFailure,
    }) => client.get<S, C>(
      url ?? Uri(),
      headers: headers,
      deserializeSuccess: (response) {
        final fn = deserializeSuccess;
        if (fn == null) {
          throw StateError(
            'get() was called and deserializeSuccess is null when it is required',
          );
        }
        return fn(response);
      },
      deserializeClientFailure: (response) {
        final fn = deserializeClientFailure;
        if (fn == null) {
          throw StateError(
            'get() was called and deserializeClientFailure is null when it is required',
          );
        }
        return fn(response);
      },
    );

    _commonTests(
      mockMakeRequest: (mock) async => mockGet(() async => mock()),
      makeRequest:
          ({
            JsonResponseDeserializer<Object>? deserializeSuccess,
            JsonResponseDeserializer<Object>? deserializeClientFailure,
            Map<String, String>? headers,
          }) => get(
            null,
            deserializeClientFailure: deserializeClientFailure,
            deserializeSuccess: deserializeSuccess,
            headers: headers,
          ),
      verifyRequest: ({required Matcher headersMatcher}) => verify(
        () => mockHttpClient.get(
          any(),
          headers: any(named: 'headers', that: headersMatcher),
        ),
      ),
    );

    test('passes arguments to ${http.Client}.get() correctly', () async {
      final url = Uri.https('example.org');
      final headers = {'example': 'header'};

      await get<void, void>(url, headers: headers);

      final expectedHeaders = {...headers, 'Accept': 'application/json'};

      verify(
        () => mockHttpClient.get(
          any(that: same(url)),
          headers: any(named: 'headers', that: equals(expectedHeaders)),
        ),
      );
    });

    test('calls ${http.Client}.get() only once', () async {
      await get<void, void>(null);

      verify(
        () => mockHttpClient.get(any(), headers: any(named: 'headers')),
      ).called(1);
      verifyNoMoreInteractions(mockHttpClient);
    });
  });

  group('post', () {
    setUp(() {
      mockPost(() async => _dummyResponse);
      mockSend(() async => _dummyResponse);
    });

    JsonApiResultFuture<S, C> post<S, C>(
      Uri? url, {
      Map<String, String>? headers,
      Object? body,
      bool isJsonBody = false,
      JsonResponseDeserializer<S>? deserializeSuccess,
      JsonResponseDeserializer<C>? deserializeClientFailure,
    }) => client.post<S, C>(
      url ?? Uri(),
      headers: headers,
      body: body,
      isJsonBody: isJsonBody,
      deserializeSuccess: (response) {
        final fn = deserializeSuccess;
        if (fn == null) {
          throw StateError(
            'post() was called and deserializeSuccess is null when it is required',
          );
        }
        return fn(response);
      },
      deserializeClientFailure: (response) {
        final fn = deserializeClientFailure;
        if (fn == null) {
          throw StateError(
            'post() was called and deserializeClientFailure is null when it is required',
          );
        }
        return fn(response);
      },
    );

    test(
      'throws $ArgumentError if isJsonBody is true but body is not a $JsonMap',
      () async {
        await expectLater(
          post<void, void>(null, isJsonBody: true, body: Object()),
          throwsArgumentError,
        );
      },
    );

    test(
      'throws $ArgumentError if isJsonBody is true but body is a $MultipartBody',
      () async {
        await expectLater(
          post<void, void>(
            null,
            isJsonBody: true,
            body: _dummyMultipartRequest,
          ),
          throwsArgumentError,
        );
      },
    );

    // Test the code that uses Client.post() when the request body is not Multipart.
    group('Non-multipart requests - ${http.Client}.post()', () {
      group('when isJsonBody is true and body is a valid $JsonMap', () {
        test('encodes body using JSON automatically', () async {
          final JsonMap body = {'username': 'Steve', 'password': '123'};

          await post<void, void>(null, isJsonBody: true, body: body);

          final String jsonBody = jsonEncode(body);

          verify(
            () => mockHttpClient.post(
              any(),
              body: any(that: equals(jsonBody), named: 'body'),
              headers: any(named: 'headers'),
            ),
          );
        });

        test('adds "Content-Type: application/json" to headers', () async {
          final passedHeaders = {'Authorization': 'Bearer eyJrcWL'};
          final expectedHeaders = {
            ...passedHeaders,
            'Content-Type': 'application/json',
          };

          final JsonMap body = {};
          await post<void, void>(
            null,
            isJsonBody: true,
            body: body,
            headers: passedHeaders,
          );

          verify(
            () => mockHttpClient.post(
              any(),
              body: any(named: 'body'),
              headers: any(
                named: 'headers',
                that: _containsHeaders(expectedHeaders),
              ),
            ),
          );
        });
      });

      test('passes arguments to ${http.Client}.post() correctly', () async {
        final url = Uri.https('example.org');
        final headers = {'example': 'header'};
        final body = Object();

        await post<void, void>(url, headers: headers, body: body);

        final expectedHeaders = {...headers, 'Accept': 'application/json'};

        verify(
          () => mockHttpClient.post(
            any(that: same(url)),
            body: any(that: same(body), named: 'body'),
            headers: any(named: 'headers', that: equals(expectedHeaders)),
          ),
        );
      });

      _commonTests(
        mockMakeRequest: (mock) async => mockPost(() async => mock()),
        makeRequest:
            ({
              JsonResponseDeserializer<Object>? deserializeSuccess,
              JsonResponseDeserializer<Object>? deserializeClientFailure,
              Map<String, String>? headers,
            }) => post(
              null,
              deserializeSuccess: deserializeSuccess,
              deserializeClientFailure: deserializeClientFailure,
              headers: headers,
            ),
        verifyRequest: ({required Matcher headersMatcher}) => verify(
          () => mockHttpClient.post(
            any(),
            body: any(named: 'body'),
            headers: any(named: 'headers', that: headersMatcher),
          ),
        ),
      );

      test('calls ${http.Client}.post() only once', () async {
        await post<void, void>(null);

        verify(
          () => mockHttpClient.post(
            any(),
            body: any(named: 'body'),
            headers: any(named: 'headers'),
          ),
        ).called(1);
        verifyNoMoreInteractions(mockHttpClient);
      });

      test('does not call ${http.Client}.send()', () async {
        await post<void, void>(null);

        verifyNever(() => mockHttpClient.send(any()));
      });
    });

    // Test the code that uses Client.send() with MultipartRequest when the request body is Multipart.
    group('Multipart requests - ${http.Client}.send()', () {
      test(
        'passes a ${http.MultipartRequest} with method POST to ${http.Client}.send()',
        () async {
          await post<void, void>(null, body: _dummyMultipartRequest);

          verify(
            () => mockHttpClient.send(
              any(
                that: isA<http.MultipartRequest>().having(
                  (e) => e.method,
                  'method',
                  equals('POST'),
                ),
              ),
            ),
          );
        },
      );

      test('passes url argument to ${http.Client}.send()', () async {
        final url = Uri.https('example.org');

        await post<void, void>(url, body: _dummyMultipartRequest);

        verify(
          () => mockHttpClient.send(
            any(
              that: isA<http.MultipartRequest>().having(
                (e) => e.url,
                'url',
                equals(url),
              ),
            ),
          ),
        );
      });

      test(
        'adds entries from the headers argument to the headers property of the ${http.MultipartRequest} passed to ${http.Client}.send()',
        () async {
          final headers = {'Authorization': 'e_example'};

          await post<void, void>(
            null,
            headers: headers,
            body: _dummyMultipartRequest,
          );

          verify(
            () => mockHttpClient.send(
              any(
                that: isA<http.MultipartRequest>().having(
                  (e) => e.headers,
                  'headers',
                  _containsHeaders(headers),
                ),
              ),
            ),
          );
        },
      );

      test(
        'adds entries from the fields property of the body argument to the fields property of the ${http.MultipartRequest} passed to ${http.Client}.send()',
        () async {
          final multipartBody = MultipartBody(
            fields: {'variant': 'classic'},
            files: [],
          );

          await post<void, void>(null, body: multipartBody);

          verify(
            () => mockHttpClient.send(
              any(
                that: isA<http.MultipartRequest>().having(
                  (e) => e.fields,
                  'fields',
                  equals(multipartBody.fields),
                ),
              ),
            ),
          );
        },
      );

      test(
        'adds files from the files property of the body argument '
        'to the files of the ${http.MultipartRequest} passed to ${http.Client}.send()',
        () async {
          final multipartBody = MultipartBody(
            fields: {},
            files: [MultipartFile.fromBytes('example', [])],
          );

          await post<void, void>(null, body: multipartBody);

          verify(
            () => mockHttpClient.send(
              any(
                that: isA<http.MultipartRequest>().having(
                  (e) => e.files,
                  'files',
                  equals(multipartBody.files),
                ),
              ),
            ),
          );
        },
      );

      _commonTests(
        mockMakeRequest: (mock) async => mockSend(() async => mock()),
        makeRequest:
            ({
              JsonResponseDeserializer<Object>? deserializeSuccess,
              JsonResponseDeserializer<Object>? deserializeClientFailure,
              Map<String, String>? headers,
            }) => post(
              null,
              body: _dummyMultipartRequest,
              deserializeSuccess: deserializeSuccess,
              deserializeClientFailure: deserializeClientFailure,
              headers: headers,
            ),
        verifyRequest: ({required Matcher headersMatcher}) => verify(
          () => mockHttpClient.send(
            any(
              that: predicate<http.BaseRequest>(
                (request) => headersMatcher.matches(request.headers, {}),
                '${http.BaseRequest} with matching headers',
              ),
            ),
          ),
        ),
      );

      test('calls ${http.Client}.send() only once', () async {
        await post<void, void>(null, body: _dummyMultipartRequest);

        verify(() => mockHttpClient.send(any())).called(1);
        verifyNoMoreInteractions(mockHttpClient);
      });

      test('does not call ${http.Client}.post()', () async {
        await post<void, void>(null, body: _dummyMultipartRequest);

        verifyNever(
          () => mockHttpClient.post(
            any(),
            body: any(named: 'body'),
            headers: any(named: 'headers'),
            encoding: any(named: 'encoding'),
          ),
        );
      });
    });
  });
}

typedef _ClientErrorResponse = Object;
typedef _MockMakeHttpRequest =
    void Function(Future<HttpResponse> Function() mock);

// Common tests for making the request, handling the transport errors and also
// handling the HTTP response.
void _commonTests({
  required _MockMakeHttpRequest mockMakeRequest,
  required JsonApiResultFuture<Object, _ClientErrorResponse> Function({
    JsonResponseDeserializer<Object>? deserializeSuccess,
    JsonResponseDeserializer<_ClientErrorResponse>? deserializeClientFailure,
    Map<String, String>? headers,
  })
  makeRequest,
  required VerificationResult Function({required Matcher headersMatcher})
  verifyRequest,
}) {
  test('returns $ConnectionFailure on $SocketException', () async {
    mockMakeRequest(() async => throw const SocketException('any'));

    final result = await makeRequest();

    expect(
      result.failureOrNull,
      isA<ConnectionFailure<_ClientErrorResponse>>(),
    );
  });

  test('adds "Accept: application/json" to headers', () async {
    final passedHeaders = {'Authorization': 'Bearer eyJrcWL'};
    final expectedHeaders = {...passedHeaders, 'Accept': 'application/json'};

    await makeRequest(headers: passedHeaders);

    verifyRequest(headersMatcher: _containsHeaders(expectedHeaders));
  });

  _testResponseHandling(
    mockMakeRequest: mockMakeRequest,
    makeRequest: makeRequest,
  );
}

// Common tests for handling the HTTP response for all HTTP methods.
void _testResponseHandling({
  required _MockMakeHttpRequest mockMakeRequest,
  required JsonApiResultFuture<Object, _ClientErrorResponse> Function({
    JsonResponseDeserializer<Object>? deserializeSuccess,
    JsonResponseDeserializer<_ClientErrorResponse>? deserializeClientFailure,
    Map<String, String>? headers,
  })
  makeRequest,
}) {
  group('2xx', () {
    test(
      'returns $JsonDecodingFailure for 2xx responses when response body is invalid JSON',
      () async {
        for (int statusCode = 200; statusCode < 300; statusCode++) {
          const responseBody = '<h1>Invalid JSON</h1>';

          mockMakeRequest(
            () async =>
                _httpResponse(statusCode: statusCode, body: responseBody),
          );

          final result = await makeRequest();

          expect(
            result.failureOrNull,
            isA<JsonDecodingFailure<_ClientErrorResponse>>(),
          );
          expect(
            result.failureOrNull,
            isA<JsonDecodingFailure<_ClientErrorResponse>>()
                .having(
                  (e) => e.responseBody,
                  'responseBody',
                  equals(responseBody),
                )
                .having(
                  (e) => e.reason,
                  'reason',
                  equals('Unexpected character'),
                ),
            reason: 'Should provide the reason with response body correctly',
          );
        }
      },
    );

    test(
      'returns $JsonDeserializationFailure for 2xx responses when JSON deserialization fails',
      () async {
        for (int statusCode = 200; statusCode < 300; statusCode++) {
          const expectedErrorReason =
              "type 'String' is not a subtype of type 'int' in type cast";
          // This error above is due to making the value of "id" as String instead of int in here.
          const responseBody = '{"id": "1", "name": "Steve"}';

          mockMakeRequest(
            () async =>
                _httpResponse(statusCode: statusCode, body: responseBody),
          );

          final result = await makeRequest(
            deserializeSuccess: (response) =>
                _FakeAccount.fromJson(response.body),
          );

          expect(
            result.failureOrNull,
            isA<JsonDeserializationFailure<_ClientErrorResponse>>(),
          );

          expect(
            result.failureOrNull,
            isA<JsonDeserializationFailure<_ClientErrorResponse>>()
                .having(
                  (e) => e.decodedJson,
                  'responseBody',
                  equals(jsonDecode(responseBody)),
                )
                .having((e) => e.reason, 'reason', equals(expectedErrorReason)),
            reason: 'Should provide the reason and response body correctly',
          );
        }
      },
    );

    test(
      'returns $SuccessResult for 2xx responses when JSON deserialization succeeds',
      () async {
        for (int statusCode = 200; statusCode < 300; statusCode++) {
          const fakeAccount = _FakeAccount(id: 1, name: 'Steve');

          final responseBody = jsonEncode(fakeAccount.toJson());
          const reasonPhrase = 'Reason Phrase';
          final headers = {'Example': 'Header'};

          mockMakeRequest(
            () async => _httpResponse(
              statusCode: statusCode,
              body: responseBody,
              reasonPhrase: reasonPhrase,
              headers: headers,
            ),
          );

          final result = await makeRequest(
            deserializeSuccess: (response) =>
                _FakeAccount.fromJson(response.body),
          );

          expect(result.failureOrNull, null);
          expect(result.valueOrNull, fakeAccount);
        }
      },
    );
  });

  group('4xx', () {
    test(
      'returns $TooManyRequestsFailure on ${HttpStatus.tooManyRequests}',
      () async {
        mockMakeRequest(
          () async => _httpResponse(statusCode: HttpStatus.tooManyRequests),
        );

        final result = await makeRequest();

        expect(
          result.failureOrNull,
          isA<TooManyRequestsFailure<_ClientErrorResponse>>(),
        );
      },
    );

    test(
      'returns $JsonDecodingFailure for 4xx responses (excluding ${HttpStatus.tooManyRequests}) when response body is invalid JSON',
      () async {
        for (int statusCode = 400; statusCode < 500; statusCode++) {
          if (statusCode == HttpStatus.tooManyRequests) {
            continue;
          }

          const responseBody = '<h1>Invalid JSON</h1>';
          mockMakeRequest(
            () async =>
                _httpResponse(statusCode: statusCode, body: responseBody),
          );

          final result = await makeRequest();

          expect(
            result.failureOrNull,
            isA<JsonDecodingFailure<_ClientErrorResponse>>(),
          );
          expect(
            result.failureOrNull,
            isA<JsonDecodingFailure<_ClientErrorResponse>>()
                .having(
                  (e) => e.responseBody,
                  'responseBody',
                  equals(responseBody),
                )
                .having(
                  (e) => e.reason,
                  'reason',
                  equals('Unexpected character'),
                ),
            reason: 'Should provide the reason with response body correctly',
          );
        }
      },
    );

    test(
      'returns $JsonDeserializationFailure for 4xx responses (excluding ${HttpStatus.tooManyRequests}) when JSON deserialization fails',
      () async {
        for (int statusCode = 400; statusCode < 500; statusCode++) {
          if (statusCode == HttpStatus.tooManyRequests) {
            continue;
          }

          const expectedErrorReason =
              "type 'String' is not a subtype of type 'int' in type cast";
          // This error above is due to making the value of "id" as String instead of int in here.
          const responseBody = '{"id": "1", "name": "Steve"}';

          mockMakeRequest(
            () async =>
                _httpResponse(statusCode: statusCode, body: responseBody),
          );

          final result = await makeRequest(
            deserializeClientFailure: (response) =>
                _FakeAccount.fromJson(response.body),
          );

          expect(
            result.failureOrNull,
            isA<JsonDeserializationFailure<_ClientErrorResponse>>(),
          );

          expect(
            result.failureOrNull,
            isA<JsonDeserializationFailure<_ClientErrorResponse>>()
                .having(
                  (e) => e.decodedJson,
                  'responseBody',
                  equals(jsonDecode(responseBody)),
                )
                .having((e) => e.reason, 'reason', equals(expectedErrorReason)),
            reason: 'Should provide the reason and response body correctly',
          );
        }
      },
    );

    test(
      'returns $ClientResponseFailure for 4xx responses (excluding ${HttpStatus.tooManyRequests}) when JSON deserialization succeeds',
      () async {
        for (int statusCode = 400; statusCode < 500; statusCode++) {
          if (statusCode == HttpStatus.tooManyRequests) {
            continue;
          }

          const fakeAccount = _FakeAccount(id: 1, name: 'Steve');

          final responseBody = jsonEncode(fakeAccount.toJson());
          const reasonPhrase = 'Reason Phrase';
          final headers = {'Example': 'Header'};

          mockMakeRequest(
            () async => _httpResponse(
              statusCode: statusCode,
              body: responseBody,
              reasonPhrase: reasonPhrase,
              headers: headers,
            ),
          );

          final result = await makeRequest(
            deserializeClientFailure: (response) =>
                _FakeAccount.fromJson(response.body),
          );

          expect(result.valueOrNull, null);
          expect(
            result.failureOrNull,
            isA<ClientResponseFailure<_ClientErrorResponse>>(),
          );
          expect(
            result.failureOrNull,
            isA<ClientResponseFailure<_ClientErrorResponse>>().having(
              (e) => e.responseBody as _FakeAccount,
              'responseBody',
              equals(fakeAccount),
            ),
            reason:
                'Should provide the client error deserialized from the response body.',
          );
          expect(
            result.failureOrNull,
            isA<ClientResponseFailure<_ClientErrorResponse>>()
                .having((e) => e.statusCode, 'statusCode', equals(statusCode))
                .having(
                  (e) => e.reasonPhrase,
                  'reasonPhrase',
                  equals(reasonPhrase),
                )
                .having((e) => e.headers, 'headers', equals(headers)),
            reason:
                'Should provide the status code, reason phrase and headers from the response correctly.',
          );
        }
      },
    );
  });

  group('5xx', () {
    test(
      'returns $ServiceUnavailableFailure on ${HttpStatus.serviceUnavailable}',
      () async {
        mockMakeRequest(
          () async => _httpResponse(statusCode: HttpStatus.serviceUnavailable),
        );

        final result = await makeRequest();

        expect(
          result.failureOrNull,
          isA<ServiceUnavailableFailure<_ClientErrorResponse>>(),
        );
      },
    );

    test(
      'provides ${HttpHeaders.retryAfterHeader} header to $ServiceUnavailableFailure on ${HttpStatus.serviceUnavailable} if available',
      () async {
        for (final isRetryAfterHeaderProvided in {true, false}) {
          const retryAfter = 120;

          final headers = isRetryAfterHeaderProvided
              ? {HttpHeaders.retryAfterHeader: '$retryAfter'}
              : <String, String>{};

          mockMakeRequest(
            () async => _httpResponse(
              statusCode: HttpStatus.serviceUnavailable,
              headers: headers,
            ),
          );

          final result = await makeRequest();

          final expectedRetryAfter = isRetryAfterHeaderProvided
              ? retryAfter
              : null;

          expect(
            result.failureOrNull,
            isNot(isA<InternalServerFailure<_ClientErrorResponse>>()),
            reason:
                'Should return $ServiceUnavailableFailure rather than $InternalServerFailure when the status code is'
                ' ${HttpStatus.serviceUnavailable} (service unavailable).',
          );
          expect(
            result.failureOrNull,
            isA<ServiceUnavailableFailure<_ClientErrorResponse>>().having(
              (e) => e.retryAfterInSeconds,
              'retryAfterInSeconds',
              equals(expectedRetryAfter),
            ),
          );
        }
      },
    );

    test(
      'returns $InternalServerFailure for 5xx errors excluding ${HttpStatus.serviceUnavailable} and ${HttpStatus.tooManyRequests}',
      () async {
        for (int statusCode = 500; statusCode < 600; statusCode++) {
          if (statusCode == HttpStatus.serviceUnavailable ||
              statusCode == HttpStatus.tooManyRequests) {
            continue;
          }

          const responseBody = 'Internal server error';

          mockMakeRequest(
            () async =>
                _httpResponse(statusCode: statusCode, body: responseBody),
          );

          final result = await makeRequest();

          expect(
            result.failureOrNull,
            isA<InternalServerFailure<_ClientErrorResponse>>(),
          );
          expect(
            result.failureOrNull,
            isA<InternalServerFailure<_ClientErrorResponse>>()
                .having(
                  (e) => e.responseBody,
                  'responseBody',
                  equals(responseBody),
                )
                .having((e) => e.statusCode, 'statusCode', equals(statusCode)),
            reason: 'Should provide correct status code and response body',
          );
        }
      },
    );
  });

  test(
    'returns $UnknownFailure for unhandled/unknown cases correctly',
    () async {
      // 3xx codes are not handled.
      const statusCode = HttpStatus.permanentRedirect;
      const responseBody = 'Unknown';

      mockMakeRequest(
        () async => _httpResponse(
          statusCode: HttpStatus.permanentRedirect,
          body: responseBody,
        ),
      );

      final result = await makeRequest();

      expect(
        result.failureOrNull,
        isA<UnknownFailure<_ClientErrorResponse>>()
            .having((e) => e.responseBody, 'responseBody', equals(responseBody))
            .having((e) => e.statusCode, 'statusCode', equals(statusCode)),
      );
    },
  );
}

HttpResponse _httpResponse({
  String? body,
  int statusCode = -1,
  Map<String, String> headers = const {},
  String? reasonPhrase,
}) => HttpResponse(
  // Some unrelated tests will fail when a bug is introduced and if this
  // JSON is invalid, keep it valid for better tests (very minor).
  // This is used by [jsonDecode] in production code.
  body: body ?? '{"dummy": "JSON"}',
  statusCode: statusCode,
  headers: headers,
  reasonPhrase: reasonPhrase,
);

class _MockHttpClient extends Mock implements http.Client {}

@immutable
class _FakeAccount {
  const _FakeAccount({required this.id, required this.name});

  factory _FakeAccount.fromJson(JsonMap json) =>
      _FakeAccount(id: json['id']! as int, name: json['name']! as String);

  JsonMap toJson() => {'id': id, 'name': name};

  final int id;
  final String name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    return other is _FakeAccount && id == other.id && name == other.name;
  }

  @override
  String toString() => 'FakeAccount(id: $id, name: $name)';
}

Matcher _containsHeaders(Map<String, String> expected) {
  return predicate<Map<String, String>>(
    (actual) => expected.entries.every((e) => actual[e.key] == e.value),
    'contains headers: ${expected.entries.map((e) => '${e.key}: ${e.value}').join(', ')}',
  );
}

final _dummyResponse = _httpResponse(statusCode: 404);

// This means the exact value of MultipartBody is irrelevant to the test
// but the body argument type should be MultipartBody to run the test correctly.
final _dummyMultipartRequest = MultipartBody.empty();

/// Converts an internal [HttpResponse] to a [http.Response] from `package:http`.
http.Response _mapHttpResponseToResponse(HttpResponse response) =>
    http.Response(
      response.body,
      response.statusCode,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
    );

/// Converts an internal [HttpResponse] to a [http.StreamedResponse] from `package:http`.
http.StreamedResponse _mapHttpResponseToStreamedResponse(
  HttpResponse response,
) {
  final bodyBytes = utf8.encode(response.body);
  final stream = Stream<List<int>>.fromIterable([bodyBytes]);

  return http.StreamedResponse(
    stream,
    response.statusCode,
    headers: response.headers,
    reasonPhrase: response.reasonPhrase,
  );
}

class _FakeBaseRequest extends Fake implements http.BaseRequest {}
