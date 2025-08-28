import 'package:api_client/src/http_response.dart';
import 'package:json_utils/json_utils.dart';
import 'package:result/result.dart';

/// Base class for all API client failures, including general and JSON-specific errors.
sealed class ApiFailure<Body> extends BaseFailure {
  const ApiFailure(super.message);
}

/// Failures for API clients that don't require JSON handling, such as connection or HTTP errors.
///
/// See also: [JsonApiFailure]
sealed class GeneralApiFailure<Body> extends ApiFailure<Body> {
  const GeneralApiFailure(super.message);
}

/// A connection issue or transport-level error.
///
/// Examples: no internet connection, DNS failure, server unreachable, or connection refused.
final class ConnectionFailure<Body> extends GeneralApiFailure<Body> {
  const ConnectionFailure(String message)
    : super('Connection failure: $message');
}

/// A failure caused by a non-successful HTTP response (non-2xx).
///
/// Includes the full HTTP response and optional reason phrase.
final class HttpStatusFailure<Body> extends GeneralApiFailure<Body> {
  HttpStatusFailure({required this.response})
    : super(
        'HTTP error ${response.statusCode}'
        '${response.reasonPhrase != null ? " (${response.reasonPhrase})" : ""}\n'
        'Response: $response',
      );

  /// Full HTTP response, including status code and body.
  final HttpResponse<Body> response;
}

/// An unexpected or unclassified failure.
final class UnexpectedFailure<Body> extends GeneralApiFailure<Body> {
  const UnexpectedFailure(String message)
    : super('Unexpected failure: $message');
}

/// Failures specific to JSON handling: decoding or deserialization errors.
sealed class JsonApiFailure<Body> extends ApiFailure<Body> {
  const JsonApiFailure(super.message);
}

/// A failure that occurs while decoding the response body as JSON.
///
/// Indicates invalid or malformed JSON.
final class JsonDecodingFailure<Body> extends JsonApiFailure<Body> {
  const JsonDecodingFailure(this.responseBody, this.reason)
    : super('JSON decoding failed: $reason\nResponse body: $responseBody');

  /// Raw response body that failed to decode.
  final String responseBody;

  /// Description of the decoding error.
  final String reason;
}

/// A failure that occurs while deserializing a decoded JSON object.
///
/// Indicates a structural or type mismatch between JSON and the expected model.
final class JsonDeserializationFailure<Body> extends JsonApiFailure<Body> {
  const JsonDeserializationFailure(this.decodedJson, this.reason)
    : super('JSON deserialization failed: $reason\nDecoded JSON: $decodedJson');

  /// Successfully decoded JSON that failed to deserialize into a model.
  final JsonMap decodedJson;

  /// Description of the deserialization error.
  final String reason;
}
