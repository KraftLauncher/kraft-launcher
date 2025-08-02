@visibleForTesting
library;

import 'package:meta/meta.dart';
import 'package:safe_http/src/api/client/json_api_client.dart';

@visibleForTesting
final class FakeJsonApiClient implements JsonApiClient {
  final List<FakeHttpGetCall<Object, Object>> _getCalls = [];
  final List<FakeHttpPostCall<Object, Object>> _postCalls = [];

  int get getCallCount => _getCalls.length;
  int get postCallCount => _postCalls.length;

  List<FakeHttpGetCall<Object, Object>> get getCalls =>
      List.unmodifiable(_getCalls);
  List<FakeHttpPostCall<Object, Object>> get postCalls =>
      List.unmodifiable(_postCalls);

  // S is SuccessResponse (2xx)
  // C is ClientErrorResponse (4xx)
  JsonApiResultFuture<S, C> Function<S, C>(FakeHttpGetCall<S, C> call)? whenGet;
  JsonApiResultFuture<S, C> Function<S, C>(FakeHttpPostCall<S, C> call)?
  whenPost;
  JsonApiResultFuture<S, C> Function<S, C>(FakeHttpCall<S, C> call)? whenAny;

  @override
  JsonApiResultFuture<S, C> get<S, C>(
    Uri url, {
    Map<String, String>? headers,
    required JsonResponseDeserializer<S> deserializeSuccess,
    required JsonResponseDeserializer<C> deserializeClientFailure,
  }) {
    final call = FakeHttpGetCall<S, C>(
      url: url,
      headers: headers,
      deserializeSuccess: deserializeSuccess,
      deserializeClientFailure: deserializeClientFailure,
    );
    _getCalls.add(call as FakeHttpGetCall<Object, Object>);

    final whenGet = this.whenGet;
    if (whenGet == null) {
      final whenAnyResult = _handleWhenAnyResult<S, C>(
        deserializeClientFailure: deserializeClientFailure,
        deserializeSuccess: deserializeSuccess,
        url: url,
        headers: headers,
      );
      if (whenAnyResult != null) {
        return whenAnyResult;
      }

      throw StateError('No return value stubbed for GET $url');
    }

    final result = whenGet.call<S, C>(call);

    return result;
  }

  JsonApiResultFuture<S, C>? _handleWhenAnyResult<S, C>({
    required Uri url,
    Map<String, String>? headers,
    required JsonResponseDeserializer<S> deserializeSuccess,
    required JsonResponseDeserializer<C> deserializeClientFailure,
  }) {
    final whenAny = this.whenAny;
    if (whenAny != null) {
      return whenAny<S, C>(
        FakeHttpCall(
          url: url,
          headers: headers,
          deserializeSuccess: deserializeSuccess,
          deserializeClientFailure: deserializeClientFailure,
        ),
      );
    }
    return null;
  }

  @override
  JsonApiResultFuture<S, C> post<S, C>(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    bool isJsonBody = false,
    required JsonResponseDeserializer<S> deserializeSuccess,
    required JsonResponseDeserializer<C> deserializeClientFailure,
  }) {
    final call = FakeHttpPostCall<S, C>(
      url: url,
      headers: headers,
      body: body,
      isJsonBody: isJsonBody,
      deserializeSuccess: deserializeSuccess,
      deserializeClientFailure: deserializeClientFailure,
    );
    _postCalls.add(call as FakeHttpPostCall<Object, Object>);

    final whenPost = this.whenPost;
    if (whenPost == null) {
      final whenAnyResult = _handleWhenAnyResult<S, C>(
        deserializeClientFailure: deserializeClientFailure,
        deserializeSuccess: deserializeSuccess,
        url: url,
        headers: headers,
      );
      if (whenAnyResult != null) {
        return whenAnyResult;
      }
      throw StateError('No return value stubbed for POST $url');
    }
    final result = whenPost.call<S, C>(call);

    return result;
  }

  void expectOnlyGetCalls(int count) {
    if (getCallCount != count) {
      throw StateError('Expected $count GET calls but found $getCallCount');
    }
    if (postCallCount != 0) {
      throw StateError('Expected 0 POST calls but found $postCallCount');
    }
  }

  void expectOnlyPostCalls(int count) {
    if (postCallCount != count) {
      throw StateError('Expected $count POST calls but found $postCallCount');
    }
    if (getCallCount != 0) {
      throw StateError('Expected 0 GET calls but found $getCallCount');
    }
  }

  void reset() {
    _getCalls.clear();
    _postCalls.clear();
    whenGet = null;
    whenPost = null;
  }
}

@visibleForTesting
final class FakeHttpGetCall<S, C> {
  FakeHttpGetCall({
    required this.url,
    required this.headers,
    required this.deserializeSuccess,
    required this.deserializeClientFailure,
  });

  final Uri url;
  final Map<String, String>? headers;
  final JsonResponseDeserializer<S> deserializeSuccess;
  final JsonResponseDeserializer<C> deserializeClientFailure;
}

@visibleForTesting
final class FakeHttpPostCall<S, C> {
  FakeHttpPostCall({
    required this.url,
    required this.headers,
    required this.body,
    required this.isJsonBody,
    required this.deserializeSuccess,
    required this.deserializeClientFailure,
  });

  final Uri url;
  final Map<String, String>? headers;
  final Object? body;
  final bool isJsonBody;
  final JsonResponseDeserializer<S> deserializeSuccess;
  final JsonResponseDeserializer<C> deserializeClientFailure;
}

@visibleForTesting
final class FakeHttpCall<S, C> {
  FakeHttpCall({
    required this.url,
    required this.headers,
    required this.deserializeSuccess,
    required this.deserializeClientFailure,
  });

  final Uri url;
  final Map<String, String>? headers;
  final JsonResponseDeserializer<S> deserializeSuccess;
  final JsonResponseDeserializer<C> deserializeClientFailure;
}
