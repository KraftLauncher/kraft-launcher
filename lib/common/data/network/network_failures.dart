import 'package:kraft_launcher/common/functional/result.dart';

// TODO: Replace this with ApiFailure from safe_http local package, currently NetworkFailure is used by MinecraftVersionsApi

sealed class NetworkFailure extends BaseFailure {
  const NetworkFailure(super.message);
}

final class TooManyRequestsFailure extends NetworkFailure {
  const TooManyRequestsFailure()
    : super('Too many requests has been sent to the server (429).');
}

final class InternalServerFailure extends NetworkFailure {
  const InternalServerFailure(this.serverMessage, this.statusCode)
    : super('Internal server error: $serverMessage. Status code: $statusCode');

  final int statusCode;
  final String serverMessage;
}

final class ServiceUnavailableFailure extends NetworkFailure {
  const ServiceUnavailableFailure({required this.retryAfterInSeconds})
    : super(
        'The service is temporarily unavailable (503). ${retryAfterInSeconds != null ? 'Please try again after $retryAfterInSeconds seconds.' : 'Please try again later.'}',
      );
  // From Retry-After header.
  final int? retryAfterInSeconds;
}

final class ConnectionFailure extends NetworkFailure {
  const ConnectionFailure(String message)
    : super(
        'Failed to connect to the server: $message\nCheck the internet connection.',
      );
}

final class UnknownFailure extends NetworkFailure {
  const UnknownFailure(String message)
    : super('Unknown failure while communicating with the server: $message');
}
