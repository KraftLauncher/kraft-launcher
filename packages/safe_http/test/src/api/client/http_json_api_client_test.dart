import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:io' show HttpHeaders, HttpStatus, SocketException;

import 'package:http/http.dart' as http;
import 'package:json_utils/json_utils.dart' show JsonMap;
import 'package:meta/meta.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result/result.dart';
import 'package:safe_http/src/api/api_failures.dart';
import 'package:safe_http/src/api/client/http_json_api_client.dart';
import 'package:safe_http/src/api/client/json_api_client.dart';
import 'package:test/test.dart';

void main() {
  late _MockHttpClient mockHttpClient;
  late JsonApiClient client;

  setUp(() {
    mockHttpClient = _MockHttpClient();
    client = HttpJsonApiClient(mockHttpClient);

    when(
      () => mockHttpClient.get(any(), headers: any(named: 'headers')),
    ).thenAnswer((_) async => _response(statusCode: 404));

    when(
      () => mockHttpClient.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
        encoding: any(named: 'encoding'),
      ),
    ).thenAnswer((_) async => _response(statusCode: 404));
  });

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  group('get', () {
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
      whenRequest: () =>
          when(() => mockHttpClient.get(any(), headers: any(named: 'headers'))),
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

    test('passes arguments to ${http.Client}.get correctly', () async {
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

    test('calls ${http.Client} once', () async {
      await get<void, void>(null);

      verify(
        () => mockHttpClient.get(any(), headers: any(named: 'headers')),
      ).called(1);
    });
  });
  group('post', () {
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

    _commonTests(
      whenRequest: () => when(
        () => mockHttpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
          encoding: any(named: 'encoding'),
        ),
      ),
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

    test(
      'throws $ArgumentError if isJsonBody is true but body is not a $JsonMap',
      () async {
        await expectLater(
          post<void, void>(null, isJsonBody: true, body: Object()),
          throwsArgumentError,
        );
      },
    );

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

    test('passes arguments to ${http.Client}.post correctly', () async {
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

    test('calls ${http.Client} once', () async {
      await post<void, void>(null);

      verify(
        () => mockHttpClient.post(
          any(),
          body: any(named: 'body'),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });
  });
}

typedef _ClientErrorResponse = Object;

void _commonTests({
  required When<Future<http.Response>> Function() whenRequest,
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
    whenRequest().thenThrow(const SocketException('any'));

    final result = await makeRequest();

    expect(
      result.failureOrNull,
      isA<ConnectionFailure<_ClientErrorResponse>>(),
    );
  });

  test('adds "Accept: application/json" to headers ', () async {
    final passedHeaders = {'Authorization': 'Bearer eyJrcWL'};
    final expectedHeaders = {...passedHeaders, 'Accept': 'application/json'};

    await makeRequest(headers: passedHeaders);

    verifyRequest(headersMatcher: _containsHeaders(expectedHeaders));
  });

  group('2xx', () {
    test(
      'returns $JsonDecodingFailure for 2xx responses when response body is invalid JSON',
      () async {
        for (int statusCode = 200; statusCode < 300; statusCode++) {
          const responseBody = '<h1>Invalid JSON</h1>';
          whenRequest().thenAnswer(
            (_) async => _response(statusCode: statusCode, body: responseBody),
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

          whenRequest().thenAnswer(
            (_) async => _response(statusCode: statusCode, body: responseBody),
          );

          final result = await makeRequest(
            deserializeSuccess: (response) =>
                _FakeAccount.fromJson(response.json),
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

          whenRequest().thenAnswer(
            (_) async => _response(
              statusCode: statusCode,
              body: responseBody,
              reasonPhrase: reasonPhrase,
              headers: headers,
            ),
          );

          final result = await makeRequest(
            deserializeSuccess: (response) =>
                _FakeAccount.fromJson(response.json),
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
        whenRequest().thenAnswer(
          (_) async => _response(statusCode: HttpStatus.tooManyRequests),
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
          whenRequest().thenAnswer(
            (_) async => _response(statusCode: statusCode, body: responseBody),
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

          whenRequest().thenAnswer(
            (_) async => _response(statusCode: statusCode, body: responseBody),
          );

          final result = await makeRequest(
            deserializeClientFailure: (response) =>
                _FakeAccount.fromJson(response.json),
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

          whenRequest().thenAnswer(
            (_) async => _response(
              statusCode: statusCode,
              body: responseBody,
              reasonPhrase: reasonPhrase,
              headers: headers,
            ),
          );

          final result = await makeRequest(
            deserializeClientFailure: (response) =>
                _FakeAccount.fromJson(response.json),
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
        whenRequest().thenAnswer(
          (_) async => _response(statusCode: HttpStatus.serviceUnavailable),
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

          whenRequest().thenAnswer(
            (_) async => _response(
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

          whenRequest().thenAnswer(
            (_) async => _response(statusCode: statusCode, body: responseBody),
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

      whenRequest().thenAnswer(
        (_) async => _response(
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

http.Response _response({
  String? body,
  int statusCode = -1,
  Map<String, String> headers = const {},
  String? reasonPhrase,
}) => http.Response(
  // Some unrelated tests will fail when a bug is introduced and if this
  // JSON is invalid, keep it valid for better tests (very minor).
  body ?? '{"dummy": "JSON"}',
  statusCode,
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
