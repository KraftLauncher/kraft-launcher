import 'dart:convert' show utf8;
import 'dart:io' show SocketException;

import 'package:api_client/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:json_utils/json_utils.dart'
    show JsonMap, jsonDecode, jsonEncode;
import 'package:meta/meta.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

const _defaultTestMethod = HttpMethod.get;

void main() {
  late _MockHttpClient mockHttpClient;
  late HttpApiClient client;

  /// Mocks the `Client.send` method from `package:http`.
  void mockSendRequest(Future<_HttpResponse> Function() getHttpResponse) {
    when(() => mockHttpClient.send(any())).thenAnswer(
      (_) async => _mapHttpResponseToStreamedResponse(await getHttpResponse()),
    );
  }

  /// Verifies interactions with the `Client.send` method from `package:http`.
  VerificationResult verifySendRequest({
    Matcher? method = _notProvided,
    Matcher? headers = _notProvided,
    Matcher? url = _notProvided,

    /// For non-multipart requests only.
    Matcher? body = _notProvided,

    /// For non-multipart requests only.
    Matcher? bodyFields = _notProvided,

    /// For multipart requests only
    Matcher? multipartBodyFields = _notProvided,

    /// For multipart requests only
    Matcher? multipartBodyFiles = _notProvided,
  }) {
    final result = verify(() => mockHttpClient.send(captureAny()));
    final capturedBaseReq = result.captured.first as http.BaseRequest;

    if (!identical(method, _notProvided)) {
      expect(capturedBaseReq.method, method);
    }

    if (!identical(headers, _notProvided)) {
      expect(capturedBaseReq.headers, headers);
    }
    if (!identical(url, _notProvided)) {
      expect(capturedBaseReq.url, url);
    }

    String expectsRequestTypeMessage(String argumentName) =>
        'Test setup failure: a non-null value was passed to $argumentName in verifySendRequest() when the request that was made is ${capturedBaseReq.runtimeType}, which is not a ${http.Request}';

    String expectsMultipartRequestTypeMessage(String argumentName) =>
        'Test setup failure: a non-null value was passed to $argumentName in verifySendRequest() when the request that was made is ${capturedBaseReq.runtimeType}, which is not a ${http.MultipartRequest}';

    if (!identical(body, _notProvided)) {
      if (capturedBaseReq is! http.Request) {
        fail(expectsRequestTypeMessage('body'));
      }
      expect(capturedBaseReq.body, body);
    }

    if (!identical(bodyFields, _notProvided)) {
      if (capturedBaseReq is! http.Request) {
        fail(expectsRequestTypeMessage('bodyFields'));
      }
      expect(capturedBaseReq.bodyFields, bodyFields);
    }

    if (!identical(multipartBodyFields, _notProvided)) {
      if (capturedBaseReq is! http.MultipartRequest) {
        fail(expectsMultipartRequestTypeMessage('multipartBodyFields'));
      }
      expect(capturedBaseReq.fields, multipartBodyFields);
    }

    if (!identical(multipartBodyFiles, _notProvided)) {
      if (capturedBaseReq is! http.MultipartRequest) {
        throw StateError(
          expectsMultipartRequestTypeMessage('multipartBodyFiles'),
        );
      }
      expect(capturedBaseReq.files, multipartBodyFiles);
    }

    return result;
  }

  void verifyNoMoreClientInteractions() =>
      verifyNoMoreInteractions(mockHttpClient);

  void commonTests({required _CommonTestsMakeRequest makeRequest}) =>
      _commonTests(
        mockMakeRequest: (mock) async => mockSendRequest(() async => mock()),
        makeRequest: makeRequest,
        verifyRequest:
            ({
              method = _notProvided,
              headers = _notProvided,
              url = _notProvided,
              body = _notProvided,
              bodyFields = _notProvided,
              multipartBodyFields = _notProvided,
              multipartBodyFiles = _notProvided,
            }) => verifySendRequest(
              method: method,
              headers: headers,
              url: url,
              body: body,
              bodyFields: bodyFields,
              multipartBodyFields: multipartBodyFields,
              multipartBodyFiles: multipartBodyFiles,
            ),
        verifyNoMoreClientInteractions: verifyNoMoreClientInteractions,
      );

  setUp(() {
    mockHttpClient = _MockHttpClient();

    client = HttpApiClient(mockHttpClient);

    mockSendRequest(() async => _httpResponse(statusCode: 200));
  });

  setUpAll(() {
    registerFallbackValue(Uri());
    registerFallbackValue(_FakeBaseRequest());
  });

  group('request', () {
    Future<StringApiResult> request({
      Uri? url,
      HttpMethod? method,
      Map<String, String>? headers,
      RequestBody? body,
    }) => client.request(
      url ?? Uri(),
      method: method ?? _defaultTestMethod,
      headers: headers,
      body: body,
    );

    test('forwards headers argument to ${http.Client}.send()', () async {
      final headers = {'example': 'header'};
      final expectedHeaders = {...headers};

      await request(headers: headers);

      verifySendRequest(headers: equals(expectedHeaders));
    });

    commonTests(
      makeRequest: ({url, body, headers, method}) =>
          request(url: url, body: body, method: method, headers: headers),
    );

    test(
      'returns $HttpResponse when a successful (2xx) response is received',
      () async {
        for (int statusCode = 200; statusCode < 300; statusCode++) {
          const responseBody = '<h1>Hello, World!</h1>';
          const reasonPhrase = 'Reason Phrase';
          final headers = {'Example': 'Header'};

          mockSendRequest(
            () async => _httpResponse(
              statusCode: statusCode,
              body: responseBody,
              reasonPhrase: reasonPhrase,
              headers: headers,
            ),
          );

          final result = await request();

          expect(result.failureOrNull, null);

          expect(result.valueOrNull?.body, responseBody);
          expect(result.valueOrNull?.statusCode, statusCode);
          expect(result.valueOrNull?.reasonPhrase, reasonPhrase);
          expect(result.valueOrNull?.headers, headers);
        }
      },
    );

    test(
      'returns $HttpStatusFailure when an error (non-2xx) response is received',
      () async {
        for (int statusCode = 400; statusCode <= 500; statusCode++) {
          const responseBody = '<h1>Unknown example error</h1>';
          const reasonPhrase = 'Reason Phrase';
          final headers = {'Example': 'Header'};

          final response = _httpResponse(
            statusCode: statusCode,
            body: responseBody,
            reasonPhrase: reasonPhrase,
            headers: headers,
          );

          mockSendRequest(() async => response);

          final result = await request();

          expect(result.valueOrNull, null);
          expect(
            result.failureOrNull,
            isA<HttpStatusFailure<_ErrorResponse>>(),
          );
          expect(
            result.failureOrNull,
            isA<HttpStatusFailure<_ErrorResponse>>().having(
              (e) => e.response.body,
              'responseBody',
              equals(responseBody),
            ),
            reason:
                'Should provide the client error deserialized from the response body.',
          );
          expect(
            result.failureOrNull,
            isA<HttpStatusFailure<_ErrorResponse>>()
                .having(
                  (e) => e.response.statusCode,
                  'statusCode',
                  equals(statusCode),
                )
                .having(
                  (e) => e.response.reasonPhrase,
                  'reasonPhrase',
                  equals(reasonPhrase),
                )
                .having((e) => e.response.headers, 'headers', equals(headers)),
            reason:
                'Should provide the status code, reason phrase and headers from the response correctly.',
          );
        }
      },
    );
  });

  group('requestJson', () {
    Future<JsonApiResult<S, F>> requestJson<S, F>({
      Uri? url,
      HttpMethod? method,
      Map<String, String>? headers,
      RequestBody? body,
      JsonResponseDeserializer<S>? deserializeSuccess,
      JsonResponseDeserializer<F>? deserializeFailure,
    }) => client.requestJson<S, F>(
      url ?? Uri(),
      method: method ?? _defaultTestMethod,
      headers: headers,
      body: body,
      deserializeSuccess: (response) {
        final fn = deserializeSuccess;
        if (fn == null) {
          throw StateError(
            'get() was called and deserializeSuccess is null when it is required',
          );
        }
        return fn(response);
      },
      deserializeFailure: (response) {
        final fn = deserializeFailure;
        if (fn == null) {
          throw StateError(
            'get() was called and deserializeFailure is null when it is required',
          );
        }
        return fn(response);
      },
    );

    commonTests(
      makeRequest: ({url, body, headers, method}) => requestJson(
        url: url,
        body: body,
        method: method,
        headers: headers,
        deserializeSuccess: null,
        deserializeFailure: null,
      ),
    );

    test('adds "Accept: application/json" to headers', () async {
      final passedHeaders = {'Authorization': 'Bearer eyJrcWL'};
      final expectedHeaders = {...passedHeaders, 'Accept': 'application/json'};

      await requestJson<void, void>(headers: passedHeaders);

      verifySendRequest(headers: _containsHeaders(expectedHeaders));
    });

    group('when a successful (2xx) response is received', () {
      test(
        'returns $JsonDecodingFailure if the response body contains invalid JSON',
        () async {
          for (int statusCode = 200; statusCode < 300; statusCode++) {
            const responseBody = '<h1>Invalid JSON</h1>';

            mockSendRequest(
              () async =>
                  _httpResponse(statusCode: statusCode, body: responseBody),
            );

            final result = await requestJson<void, _ErrorResponse>();

            expect(
              result.failureOrNull,
              isA<JsonDecodingFailure<_ErrorResponse>>(),
            );
            expect(
              result.failureOrNull,
              isA<JsonDecodingFailure<_ErrorResponse>>()
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
        'returns $JsonDeserializationFailure if JSON deserialization fails',
        () async {
          for (int statusCode = 200; statusCode < 300; statusCode++) {
            const expectedErrorReason =
                "type 'String' is not a subtype of type 'int' in type cast";
            // This error above is due to making the value of "id" as String instead of int in here.
            const responseBody = '{"id": "1", "name": "Steve"}';

            mockSendRequest(
              () async =>
                  _httpResponse(statusCode: statusCode, body: responseBody),
            );

            final result = await requestJson<void, _ErrorResponse>(
              deserializeSuccess: (response) =>
                  _FakeAccount.fromJson(response.body),
            );

            expect(
              result.failureOrNull,
              isA<JsonDeserializationFailure<_ErrorResponse>>(),
            );

            expect(
              result.failureOrNull,
              isA<JsonDeserializationFailure<_ErrorResponse>>()
                  .having(
                    (e) => e.decodedJson,
                    'responseBody',
                    equals(jsonDecode(responseBody)),
                  )
                  .having(
                    (e) => e.reason,
                    'reason',
                    equals(expectedErrorReason),
                  ),
              reason: 'Should provide the reason and response body correctly',
            );
          }
        },
      );

      test(
        'returns $HttpResponse with deserialized body if JSON deserialization succeeds',
        () async {
          for (int statusCode = 200; statusCode < 300; statusCode++) {
            const fakeAccount = _FakeAccount(id: 1, name: 'Steve');

            final responseBody = jsonEncode(fakeAccount.toJson());
            const reasonPhrase = 'Reason Phrase';
            final headers = {'Example': 'Header'};

            mockSendRequest(
              () async => _httpResponse(
                statusCode: statusCode,
                body: responseBody,
                reasonPhrase: reasonPhrase,
                headers: headers,
              ),
            );

            final result = await requestJson<_FakeAccount, _ErrorResponse>(
              deserializeSuccess: (response) =>
                  _FakeAccount.fromJson(response.body),
            );

            expect(result.failureOrNull, null);

            expect(result.valueOrNull?.body, fakeAccount);
            expect(result.valueOrNull?.statusCode, statusCode);
            expect(result.valueOrNull?.reasonPhrase, reasonPhrase);
            expect(result.valueOrNull?.headers, headers);
          }
        },
      );
    });

    group('when an error (non-2xx) response is received', () {
      test(
        'returns $JsonDecodingFailure if the response body contains invalid JSON',
        () async {
          for (int statusCode = 400; statusCode <= 500; statusCode++) {
            const responseBody = '<h1>Invalid JSON</h1>';
            mockSendRequest(
              () async =>
                  _httpResponse(statusCode: statusCode, body: responseBody),
            );

            final result = await requestJson<void, _ErrorResponse>();

            expect(
              result.failureOrNull,
              isA<JsonDecodingFailure<_ErrorResponse>>(),
            );
            expect(
              result.failureOrNull,
              isA<JsonDecodingFailure<_ErrorResponse>>()
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
        'returns $JsonDeserializationFailure if JSON deserialization fails',
        () async {
          for (int statusCode = 400; statusCode <= 500; statusCode++) {
            const expectedErrorReason =
                "type 'String' is not a subtype of type 'int' in type cast";
            // This error above is due to making the value of "id" as String instead of int in here.
            const responseBody = '{"id": "1", "name": "Steve"}';

            mockSendRequest(
              () async =>
                  _httpResponse(statusCode: statusCode, body: responseBody),
            );

            final result = await requestJson<void, _ErrorResponse>(
              deserializeFailure: (response) =>
                  _FakeAccount.fromJson(response.body),
            );

            expect(
              result.failureOrNull,
              isA<JsonDeserializationFailure<_ErrorResponse>>(),
            );

            expect(
              result.failureOrNull,
              isA<JsonDeserializationFailure<_ErrorResponse>>()
                  .having(
                    (e) => e.decodedJson,
                    'responseBody',
                    equals(jsonDecode(responseBody)),
                  )
                  .having(
                    (e) => e.reason,
                    'reason',
                    equals(expectedErrorReason),
                  ),
              reason: 'Should provide the reason and response body correctly',
            );
          }
        },
      );

      test('returns $HttpStatusFailure if JSON deserialization succeeds', () async {
        for (int statusCode = 400; statusCode <= 500; statusCode++) {
          const fakeAccount = _FakeAccount(id: 1, name: 'Steve');

          final responseBody = jsonEncode(fakeAccount.toJson());
          const reasonPhrase = 'Reason Phrase';
          final headers = {'Example': 'Header'};

          final response = _httpResponse(
            statusCode: statusCode,
            body: responseBody,
            reasonPhrase: reasonPhrase,
            headers: headers,
          );

          mockSendRequest(() async => response);

          final result = await requestJson<void, _ErrorResponse>(
            deserializeFailure: (response) =>
                _FakeAccount.fromJson(response.body),
          );

          expect(result.valueOrNull, null);
          expect(
            result.failureOrNull,
            isA<HttpStatusFailure<_ErrorResponse>>(),
          );
          expect(
            result.failureOrNull,
            isA<HttpStatusFailure<_ErrorResponse>>().having(
              (e) => e.response.body as _FakeAccount,
              'responseBody',
              equals(fakeAccount),
            ),
            reason:
                'Should provide the client error deserialized from the response body.',
          );
          expect(
            result.failureOrNull,
            isA<HttpStatusFailure<_ErrorResponse>>()
                .having(
                  (e) => e.response.statusCode,
                  'statusCode',
                  equals(statusCode),
                )
                .having(
                  (e) => e.response.reasonPhrase,
                  'reasonPhrase',
                  equals(reasonPhrase),
                )
                .having((e) => e.response.headers, 'headers', equals(headers)),
            reason:
                'Should provide the status code, reason phrase and headers from the response correctly.',
          );
        }
      });
    });

    test('forwards headers argument to ${http.Client}.send()', () async {
      final headers = {'example': 'header'};
      final expectedHeaders = {...headers, 'Accept': 'application/json'};

      await requestJson<void, void>(headers: headers);

      verifySendRequest(headers: equals(expectedHeaders));
    });
  });
}

typedef _ErrorResponse = Object;
typedef _MockMakeHttpRequest =
    void Function(Future<_HttpResponse> Function() mock);

typedef _CommonTestsMakeRequest =
    Future<JsonApiResult<Object, _ErrorResponse>> Function({
      Uri? url,
      Map<String, String>? headers,
      RequestBody? body,
      HttpMethod? method,
    });

/// Common tests for making the request, handling the transport errors and also
/// handling the HTTP response.
/// Callers should provide default value that's [_notProvided]
/// instead of null, when passing a value to [verifyRequest] argument.
void _commonTests({
  required _MockMakeHttpRequest mockMakeRequest,
  required _CommonTestsMakeRequest makeRequest,
  required VerificationResult Function({
    Matcher? method,
    Matcher? headers,
    Matcher? url,
    Matcher? body,
    Matcher? bodyFields,
    Matcher? multipartBodyFields,
    Matcher? multipartBodyFiles,
  })
  verifyRequest,
  required void Function() verifyNoMoreClientInteractions,
}) {
  test('returns $ConnectionFailure on $SocketException', () async {
    mockMakeRequest(() async => throw const SocketException('any'));

    final result = await makeRequest();

    expect(result.failureOrNull, isA<ConnectionFailure<_ErrorResponse>>());
  });

  test('returns $UnexpectedFailure for unhandled cases correctly', () async {
    mockMakeRequest(() async => throw const FormatException());

    final result = await makeRequest();

    expect(result.failureOrNull, isA<UnexpectedFailure<_ErrorResponse>>());
  });

  for (final method in HttpMethod.values._withNoRequestBodies()) {
    test(
      'throws $ArgumentError when HTTP ${method.httpName} request is given a non-null body',
      () async {
        await expectLater(
          makeRequest(body: const RequestBody.raw({}), method: method),
          throwsArgumentError,
        );
      },
    );
  }

  group('Multipart requests', () {
    // Multipart requests send a [MultipartRequest] instead of [Request].
    for (final method in HttpMethod.values._withRequestBodies()) {
      test(
        'passes a ${http.MultipartRequest} with method "${method.httpName}" to ${http.Client}.send()',
        () async {
          await makeRequest(
            body: RequestBody.multipart(_dummyMultipartRequest),
            method: method,
          );

          verifyRequest(method: equals(method.httpName));
        },
      );

      test('passes url argument to ${http.Client}.send()', () async {
        final url = Uri.https('example.org');

        await makeRequest(
          body: RequestBody.multipart(_dummyMultipartRequest),
          method: method,
          url: url,
        );

        verifyRequest(url: equals(url));
      });

      test(
        'adds entries from the headers argument to the headers property of the ${http.MultipartRequest} passed to ${http.Client}.send()',
        () async {
          final headers = {'Authorization': 'e_example'};

          await makeRequest(
            headers: headers,
            body: RequestBody.multipart(_dummyMultipartRequest),
            method: method,
          );

          verifyRequest(headers: _containsHeaders(headers));
        },
      );

      test(
        'adds entries from the fields property of the body argument to the fields property of the ${http.MultipartRequest} passed to ${http.Client}.send()',
        () async {
          final multipartBody = MultipartBody(
            fields: {'variant': 'classic'},
            files: [],
          );

          await makeRequest(
            body: RequestBody.multipart(multipartBody),
            method: method,
          );

          verifyRequest(multipartBodyFields: equals(multipartBody.fields));
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

          await makeRequest(
            body: RequestBody.multipart(multipartBody),
            method: method,
          );

          verifyRequest(multipartBodyFiles: equals(multipartBody.files));
        },
      );

      test('calls ${http.Client}.send() only once', () async {
        await makeRequest(method: method);

        verifyRequest().called(1);
        verifyNoMoreClientInteractions();
      });
    }
  });

  group('Non-multipart requests', () {
    // Non-multipart requests send a [Request] instead of [MultipartRequest].

    for (final method in HttpMethod.values._withRequestBodies()) {
      test(
        'adds "Content-Type: application/json" to headers for ${method.httpName} '
        'requests when body argument is a $JsonRequestBody',
        () async {
          final passedHeaders = {'Authorization': 'Bearer eyJrcWL'};
          final expectedHeaders = {
            ...passedHeaders,
            // Note: we pass "application/json", but package:http automatically
            // normalizes it to "application/json; charset=utf-8" in [BaseRequest].
            // Since we capture and verify the BaseRequest, we need to check for
            // the normalized value instead of the original one.
            // This applies only to "Content-Type" header and not "Accept".
            'Content-Type': 'application/json; charset=utf-8',
          };
          final JsonMap body = {};

          await makeRequest(
            body: RequestBody.json(body),
            headers: passedHeaders,
            method: method,
          );

          verifyRequest(headers: _containsHeaders(expectedHeaders));
        },
      );

      test(
        'encodes map from $JsonRequestBody argument to JSON string and forwards it to '
        '${http.Client}.send() for ${method.httpName} requests',
        () async {
          final JsonMap body = {'username': 'Steve', 'password': '123'};
          final String expectedJsonBody = jsonEncode(body);

          await makeRequest(body: RequestBody.json(body), method: method);

          verifyRequest(body: equals(expectedJsonBody));
        },
      );

      test(
        'forwards raw value from $RawRequestBody argument to ${http.Client}.send() for ${method.httpName} requests',
        () async {
          final body = {
            'application/x-www-form-urlencoded': 'body fields example',
          };

          await makeRequest(body: RequestBody.raw(body), method: method);

          verifyRequest(bodyFields: equals(body));
        },
      );
    }

    for (final method in HttpMethod.values) {
      test(
        'passes a ${http.Request} with method "${method.httpName}" to ${http.Client}.send()',
        () async {
          await makeRequest(method: method);

          verifyRequest(method: equals(method.httpName));
        },
      );
    }

    test('forwards url argument to ${http.Client}.send()', () async {
      final url = Uri.https('example.org');

      await makeRequest(url: url);

      verifyRequest(url: equals(url));
    });

    test('calls ${http.Client}.send() only once', () async {
      await makeRequest();

      verifyRequest().called(1);
      verifyNoMoreClientInteractions();
    });
  });
}

_HttpResponse _httpResponse({
  String? body,
  int statusCode = -1,
  Map<String, String> headers = const {},
  String? reasonPhrase,
}) => _HttpResponse(
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

// This means the exact value of MultipartBody is irrelevant to the test
// but the body argument type should be MultipartBody to run the test correctly.
final _dummyMultipartRequest = MultipartBody.empty();

/// Converts an internal [_HttpResponse] to a [http.StreamedResponse] from `package:http`.
http.StreamedResponse _mapHttpResponseToStreamedResponse(
  _HttpResponse response,
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

typedef _HttpResponse = StringHttpResponse;

/// Internal sentinel to detect when a matcher was not passed.
class _NotProvided implements Matcher {
  const _NotProvided();

  // Stub implementation for compile the code, it will never be used.

  @override
  Description describe(Description description) {
    throw UnsupportedError(
      '$_NotProvided matcher is a stub and should never be used but describe() was called.',
    );
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    throw UnsupportedError(
      '$_NotProvided matcher is a stub and should never be used but describeMismatch() was called.',
    );
  }

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    throw UnsupportedError(
      '$_NotProvided matcher is a stub and should never be used but matches() was called.',
    );
  }
}

const _notProvided = _NotProvided();

extension _HttpRequestBodyMethods on List<HttpMethod> {
  Iterable<HttpMethod> _withRequestBodies() =>
      where((method) => method.supportsRequestBody);

  Iterable<HttpMethod> _withNoRequestBodies() =>
      where((method) => !method.supportsRequestBody);
}
