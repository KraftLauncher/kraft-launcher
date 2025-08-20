@visibleForTesting
library;

import 'package:api_client/src/api_client.dart';
import 'package:api_client/src/api_failures.dart' show ConnectionFailure;
import 'package:api_client/src/request_body.dart';
import 'package:api_client/src/test/http_response_dummy.dart';
import 'package:json_utils/json_utils.dart';
import 'package:meta/meta.dart';
import 'package:result/result.dart';

@visibleForTesting
final class FakeApiClient implements ApiClient {
  final List<FakeHttpRequestCall> _requestCalls = [];
  final List<FakeHttpRequestJsonCall<Object, Object>> _requestJsonCalls = [];

  int get requestCallCount => _requestCalls.length;
  int get requestJsonCallCount => _requestJsonCalls.length;

  List<FakeHttpRequestCall> get requestCalls =>
      List.unmodifiable(_requestCalls);
  List<FakeHttpRequestJsonCall<Object, Object>> get requestJsonCalls =>
      List.unmodifiable(_requestJsonCalls);

  StringApiResultFuture Function(FakeHttpRequestCall call)? whenRequest;
  JsonApiResultFuture<S, F> Function<S, F>(FakeHttpRequestJsonCall<S, F> call)?
  whenRequestJson;

  Future<void> stubJsonSuccessAndRun<T>({
    required JsonMap json,
    required T expectedDecodedBody,
    required void Function(T result) assertion,
    required Future<void> Function() makeRequest,
  }) async {
    whenRequestJson = <S, F>(call) async {
      final result =
          call.deserializeSuccess(dummyJsonHttpResponse(body: json)) as T;

      assertion(result);

      return Result.success(dummyHttpResponse(body: result as S));
    };

    await makeRequest();
  }

  Future<void> stubJsonFailureAndRun<T>({
    required JsonMap json,
    required T expectedDecodedBody,
    required void Function(T result) assertion,
    required Future<void> Function() makeRequest,
  }) async {
    whenRequestJson = <S, F>(call) async {
      final result =
          call.deserializeFailure(dummyJsonHttpResponse(body: json)) as T;

      assertion(result);

      final dummyResult = JsonApiResult<S, F>.failure(
        const ConnectionFailure('any'),
      );
      return dummyResult;
    };

    await makeRequest();
  }

  // Currently not needed, but archived just in case.
  // Future<void> stubJsonResultAndRun<T>({
  //   required JsonApiResult<T, Object> expectedResult,
  //   required Future<JsonApiResult<T, Object>> Function() makeRequest,
  //   required void Function(T result) assertion,
  // }) async {
  //   whenRequestJson = <S, F>(call) async {
  //     return expectedResult as JsonApiResult<S, F>;
  //   };

  //   final result = await makeRequest();

  //   assertion(result.valueOrThrow.body);
  // }

  @override
  StringApiResultFuture request(
    Uri url, {
    required HttpMethod method,
    Map<String, String>? headers,
    RequestBody? body,
  }) {
    final call = FakeHttpRequestCall(
      url: url,
      headers: headers,
      method: method,
      body: body,
    );
    _requestCalls.add(call);

    final whenRequest = this.whenRequest;
    if (whenRequest == null) {
      throw StateError(
        'No return value stubbed for $requestMethodName($url, method: $HttpMethod.${method.name})',
      );
    }
    final result = whenRequest.call(call);

    return result;
  }

  @override
  JsonApiResultFuture<S, F> requestJson<S, F>(
    Uri url, {
    required HttpMethod method,
    Map<String, String>? headers,
    RequestBody? body,
    required JsonResponseDeserializer<S> deserializeSuccess,
    required JsonResponseDeserializer<F> deserializeFailure,
  }) {
    final call = FakeHttpRequestJsonCall<S, F>(
      url: url,
      headers: headers,
      method: method,
      deserializeSuccess: deserializeSuccess,
      deserializeFailure: deserializeFailure,
      body: body,
    );
    _requestJsonCalls.add(call as FakeHttpRequestJsonCall<Object, Object>);

    final whenRequestJson = this.whenRequestJson;
    if (whenRequestJson == null) {
      throw StateError(
        'No return value stubbed for $requestJsonMethodName($url, method: $HttpMethod.${method.name})',
      );
    }

    final result = whenRequestJson.call<S, F>(call);

    return result;
  }

  static const requestJsonMethodName = 'requestJson';
  static const requestMethodName = 'request';

  void expectOnlyRequestCalls(int count) {
    if (requestCallCount != count) {
      throw StateError(
        'Expected $count $requestMethodName() calls but found $requestCallCount',
      );
    }
    if (requestJsonCallCount != 0) {
      throw StateError(
        'Expected 0 $requestJsonMethodName() calls but found $requestJsonCallCount',
      );
    }
  }

  void expectOnlyRequestJsonCalls(int count) {
    if (requestJsonCallCount != count) {
      throw StateError(
        'Expected $count $requestJsonMethodName() calls but found $requestJsonCallCount',
      );
    }
    if (requestCallCount != 0) {
      throw StateError(
        'Expected 0 $requestMethodName() calls but found $requestCallCount',
      );
    }
  }

  void expectSingleRequest({
    required bool isRequestJsonMethod,
    required HttpMethod method,
  }) {
    if (isRequestJsonMethod) {
      expectOnlyRequestJsonCalls(1);
    } else {
      expectOnlyRequestCalls(1);
    }

    final capturedMethod = requestJsonCalls.first.method;
    if (method != capturedMethod) {
      throw StateError(
        'Expected $HttpMethod.${method.name}, but got $capturedMethod.',
      );
    }
  }

  void reset() {
    _requestCalls.clear();
    _requestJsonCalls.clear();
    whenRequest = null;
    whenRequestJson = null;
  }
}

/// Shares properties between [FakeHttpRequestJsonCall] and [FakeHttpRequestCall].
@visibleForTesting
final class FakeHttpCall {
  FakeHttpCall({
    required this.url,
    required this.headers,
    required this.method,
    required this.body,
  });

  final Uri url;
  final Map<String, String>? headers;
  final HttpMethod method;

  final RequestBody? body;
}

@visibleForTesting
final class FakeHttpRequestJsonCall<S, F> {
  FakeHttpRequestJsonCall({
    required this.url,
    required this.headers,
    required this.method,
    required this.body,
    required this.deserializeSuccess,
    required this.deserializeFailure,
  });

  final Uri url;
  final Map<String, String>? headers;
  final HttpMethod method;

  final RequestBody? body;
  final JsonResponseDeserializer<S> deserializeSuccess;
  final JsonResponseDeserializer<F> deserializeFailure;
}

@visibleForTesting
final class FakeHttpRequestCall {
  FakeHttpRequestCall({
    required this.url,
    required this.headers,
    required this.method,
    required this.body,
  });

  final Uri url;
  final Map<String, String>? headers;
  final HttpMethod method;

  final RequestBody? body;
}
