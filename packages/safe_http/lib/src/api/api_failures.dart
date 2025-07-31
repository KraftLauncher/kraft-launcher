import 'package:json_utils/json_utils.dart';
import 'package:result/result.dart';

sealed class ApiFailure<ClientResponseBody> extends BaseFailure {
  const ApiFailure(super.message);
}

final class ConnectionFailure<ClientResponseBody>
    extends ApiFailure<ClientResponseBody> {
  const ConnectionFailure(String message)
    : super(
        'Failed to connect to the server: $message\nCheck the internet connection.',
      );
}

// JSON

final class JsonDecodingFailure<ClientResponseBody>
    extends ApiFailure<ClientResponseBody> {
  const JsonDecodingFailure(this.responseBody, this.reason)
    : super(
        'Failed to decode JSON. Reason: $reason\nResponse Body: $responseBody',
      );
  final String responseBody;
  final String reason;
}

final class JsonDeserializationFailure<ClientResponseBody>
    extends ApiFailure<ClientResponseBody> {
  const JsonDeserializationFailure(this.decodedJson, this.reason)
    : super('Failed to deserialize JSON. Reason: $reason\nInput: $decodedJson');
  final JsonMap decodedJson;
  final String reason;
}

// 4xx

final class TooManyRequestsFailure<ClientResponseBody>
    extends ApiFailure<ClientResponseBody> {
  const TooManyRequestsFailure()
    : super('Too many requests has been sent to the server (429).');
}

// For all 4xx client errors except 429 (Too Many Requests)

final class ClientResponseFailure<ResponseBody>
    extends ApiFailure<ResponseBody> {
  const ClientResponseFailure({
    required this.statusCode,
    required this.reasonPhrase,
    required this.responseBody,
    required this.headers,
  }) : super(
         'HTTP Client error ($statusCode): $responseBody. Reason Phrase: $reasonPhrase',
       );

  final int statusCode;
  final String? reasonPhrase;
  final ResponseBody responseBody;
  final Map<String, String> headers;
}

// 5xx

final class InternalServerFailure<ClientResponseBody>
    extends ApiFailure<ClientResponseBody> {
  const InternalServerFailure({
    required this.statusCode,
    required this.responseBody,
  }) : super('Internal server error ($statusCode): $responseBody');

  final int statusCode;
  final String responseBody;
}

final class ServiceUnavailableFailure<ClientResponseBody>
    extends ApiFailure<ClientResponseBody> {
  const ServiceUnavailableFailure({required this.retryAfterInSeconds})
    : super(
        'The service is temporarily unavailable (503). ${retryAfterInSeconds != null ? 'Please try again after $retryAfterInSeconds seconds.' : 'Please try again later.'}',
      );
  // From Retry-After header.
  final int? retryAfterInSeconds;
}

// Unknown/unhandled.

final class UnknownFailure<ClientResponseBody>
    extends ApiFailure<ClientResponseBody> {
  const UnknownFailure(
    String message, {
    required this.statusCode,
    required this.responseBody,
  }) : super('Unknown failure while communicating with the server: $message');

  final int statusCode;
  final String responseBody;
}
