import 'package:json_utils/json_utils.dart';
import 'package:meta/meta.dart';
import 'package:result/result.dart';
import 'package:safe_http/src/api/api_failures.dart';

/// A JSON-based HTTP client for APIs that return structured responses
/// for both success (2xx) and client errors (4xx).
///
/// Provides the following on top of a standard HTTP client:
///
/// * Wraps all responses in a [Result], with standardized failure types
///   such as service unavailability or too many requests.
/// * Automatically adds the `Accept: application/json` header and expects
///   all 2xx and 4xx responses (except 429) to be JSON.
/// * Optionally encodes the request body as JSON and sets
///   `Content-Type: application/json` when sending a JSON body.
///
/// Example:
///
/// ```dart
/// final JsonApiClient jsonApiClient = ...;
///
/// final result = await jsonApiClient.get<Example, String>(
///   Uri.https('api.example.com'),
///   deserializeSuccess: (jsonMap, statusCode) => Example.fromJson(jsonMap),
///   deserializeClientFailure: (jsonMap, statusCode) => jsonMap['error_code']! as String,
/// );
/// ```
abstract interface class JsonApiClient {
  /// Sends a GET request and deserializes the JSON response.
  JsonApiResultFuture<S, C> get<S, C>(
    Uri url, {
    Map<String, String>? headers,
    required JsonResponseDeserializer<S> deserializeSuccess,
    required JsonResponseDeserializer<C> deserializeClientFailure,
  });

  /// Sends a POST request with optional [body] and deserializes the JSON response.
  ///
  /// When [isJsonBody] is `true`, the [body] is expected to be a [JsonMap]
  /// and will be automatically JSON-encoded. In this case, the
  /// `Content-Type: application/json` header is added.
  ///
  /// Throws an [ArgumentError] if [isJsonBody] is `true` but [body] is not a [JsonMap].
  ///
  /// If [isJsonBody] is `false`, [body] is passed as-is to the HTTP client.
  JsonApiResultFuture<S, C> post<S, C>(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    bool isJsonBody = false,
    required JsonResponseDeserializer<S> deserializeSuccess,
    required JsonResponseDeserializer<C> deserializeClientFailure,
  });
}

@immutable
class JsonResponse {
  const JsonResponse({required this.json, required this.statusCode});

  final JsonMap json;
  final int statusCode;

  @override
  String toString() => 'JsonResponse(statusCode: $statusCode, json: $json)';
}

typedef JsonResponseDeserializer<T> = T Function(JsonResponse response);

// S is the SuccessResponse
// C is the ClientErrorResponse

typedef JsonApiResult<S, C> = Result<S, ApiFailure<C>>;
typedef JsonApiResultFuture<S, C> = Future<JsonApiResult<S, C>>;
