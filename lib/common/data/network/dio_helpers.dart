import 'dart:io';

import 'package:dio/dio.dart';
import 'package:kraft_launcher/common/data/network/network_failures.dart';
import 'package:kraft_launcher/common/models/result.dart';

// TODO: Use safeHttpApiCall in MicrosoftAuthApi and MinecraftAccountApi (which will handle common failures).

// Handles common failures when sending an HTTP request to APIs using Dio.
Future<Result<V, F>> safeHttpApiCall<V, F extends BaseFailure>(
  Future<V> Function() run, {
  required F Function(String message) onDeserializationFailure,
  required F Function(String message) onConnectionFailure,
  required F Function() onTooManyRequestsFailure,
  required F Function(int? retryAfterInSeconds) onServiceUnavailable,
  required F Function(String message, int statusCode) onInternalServerError,
  required F Function(DioException e) onUnknownFailure,
  F? Function(DioException e)? onCustomFailure,
}) async {
  try {
    return Result.success(await run());
  } on DioException catch (e) {
    final customFailure = onCustomFailure?.call(e);
    if (customFailure != null) {
      return Result.failure(customFailure);
    }

    final networkFailure = e._toNetworkFailure();
    final failure = switch (networkFailure) {
      TooManyRequestsFailure() => onTooManyRequestsFailure(),
      InternalServerFailure() => onInternalServerError(
        networkFailure.serverMessage,
        networkFailure.statusCode,
      ),
      ConnectionFailure() => onConnectionFailure(
        e.message ?? 'Unknown connection error. Message is null.',
      ),
      ServiceUnavailableFailure() => onServiceUnavailable(
        networkFailure.retryAfterInSeconds,
      ),
      UnknownFailure() => onUnknownFailure(e),
    };

    return Result.failure(failure);
  } on FormatException catch (e) {
    // TODO: This is probably handled incorrectly, DIO maps Errors/Exceptions to DioException. See: https://pub.dev/packages/dio#handling-errors
    // This is not specific to Dio and can be thrown when calling jsonDecode with an invalid JSON String.
    // All of the APIs this app communicates with use JSON.
    return Result.failure(onDeserializationFailure(e.message));
  }
}

extension DioResponseExt<T> on Response<T> {
  T get dataOrThrow {
    final responseData = data;
    if (responseData == null) {
      throw StateError("The response data can't be null.");
    }
    return responseData;
  }
}

extension DioExceptionExt on DioException {
  String get userErrorMessage =>
      'Response: ${response?.data}.\n Message: ${message ?? toString()}';

  NetworkFailure _toNetworkFailure() {
    if (type == DioExceptionType.connectionError) {
      return ConnectionFailure(message.toString());
    }

    final response = this.response;

    if (response != null) {
      final statusCode = response.statusCode;
      if (response.statusCode == HttpStatus.tooManyRequests) {
        return const TooManyRequestsFailure();
      }
      if (response.statusCode == HttpStatus.serviceUnavailable) {
        return ServiceUnavailableFailure(
          retryAfterInSeconds:
              response.headers[HttpHeaders.retryAfterHeader] as int?,
        );
      }

      if (statusCode != null) {
        final isServerError = statusCode >= 500 && statusCode < 600;
        if (isServerError) {
          return InternalServerFailure(response.data.toString(), statusCode);
        }
      }
    }

    return UnknownFailure(
      'Unknown or handled $DioException.\n'
      'Status code: ${response?.statusCode}.\n'
      'Response: ${response?.data}\n'
      'Message: $message',
    );
  }
}
