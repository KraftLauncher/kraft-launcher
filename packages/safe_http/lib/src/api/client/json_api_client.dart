import 'package:json_utils/json_utils.dart';
import 'package:result/result.dart';
import 'package:safe_http/src/api/api_failures.dart';

/// A JSON-based HTTP client for APIs that return structured responses
/// for both success (2xx) and client errors (4xx).
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
  JsonApiResult<Response, ClientError> get<Response, ClientError>(
    Uri url, {
    Map<String, String>? headers,
    required JsonResponseDeserializer<Response> deserializeSuccess,
    required JsonResponseDeserializer<ClientError> deserializeClientFailure,
  });

  /// Sends a POST request with optional [body] and deserializes the JSON response.
  JsonApiResult<Response, ClientError> post<Response, ClientError>(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    required JsonResponseDeserializer<Response> deserializeSuccess,
    required JsonResponseDeserializer<ClientError> deserializeClientFailure,
  });
}

typedef JsonResponseDeserializer<T> = T Function(JsonMap json, int statusCode);
typedef JsonApiResult<Response, ClientError> =
    Future<Result<Response, ApiFailure<ClientError>>>;
