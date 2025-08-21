import 'package:kraft_launcher/common/functional/result.dart';

sealed class MinecraftVersionsApiFailure extends BaseFailure {
  const MinecraftVersionsApiFailure(super.message);
}

final class DeserializationFailure extends MinecraftVersionsApiFailure {
  const DeserializationFailure(String decodingFailureMessage)
    : super('Failed to decode the server response: $decodingFailureMessage');
}

final class TooManyRequestsFailure extends MinecraftVersionsApiFailure {
  const TooManyRequestsFailure()
    : super('Too many requests has been sent to Mojang servers.');
}

final class InternalServerFailure extends MinecraftVersionsApiFailure {
  const InternalServerFailure(String message)
    : super('Internal Mojang server error: $message');
}

final class ServiceUnavailable extends MinecraftVersionsApiFailure {
  const ServiceUnavailable(int? retryAfterInSeconds)
    : super(
        'Mojang servers are temporarily unavailable. Please try again in $retryAfterInSeconds',
      );
}

final class ConnectionFailure extends MinecraftVersionsApiFailure {
  const ConnectionFailure(String message)
    : super('Failed to connect to Mojang servers: $message');
}

final class UnknownFailure extends MinecraftVersionsApiFailure {
  const UnknownFailure(String message)
    : super(
        'Unknown failure while communicating with Mojang servers: $message',
      );
}
