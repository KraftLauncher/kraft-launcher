import 'dart:io';

import 'package:dio/dio.dart';

// TODO: Try to use this function in MicrosoftAuthApi and MinecraftAccountApi.
// TODO: Handle onDeserializationFailure also in everywhere where jsonDecode is used, also in MicrosoftAuthApi and MinecraftAccountApi. (Unrelated to code in this file).

// Common failures when sending a request using Dio.
Future<T> handleCommonDioFailures<T>(
  Future<T> Function() run, {
  required T Function(String message) onDeserializationFailure,
  required T Function(String message) onConnectionFailure,
  T Function(String message)? onBadResponseFailure,
  required T Function() onTooManyRequestsFailure,
  T Function()? onServiceUnavailable,
  required T Function(DioException e) onUnknownFailure,
  T? Function(DioException e)? handleFailure,
}) async {
  try {
    return run();
  } on DioException catch (e) {
    final specialHandleResult = handleFailure?.call(e);
    if (specialHandleResult != null) {
      return specialHandleResult;
    }

    if (e.type == DioExceptionType.connectionError) {
      return onConnectionFailure(
        e.message ?? 'Unknown connection error. Message is null.',
      );
    }
    if (e.type == DioExceptionType.badResponse) {
      final result = onBadResponseFailure?.call(
        e.message ?? 'Unknown bad response error. Message is null.',
      );
      if (result != null) {
        return result;
      }
    }
    if (e.response?.statusCode == HttpStatus.tooManyRequests) {
      return onTooManyRequestsFailure();
    }
    if (e.response?.statusCode == HttpStatus.serviceUnavailable) {
      final result = onServiceUnavailable?.call();
      if (result != null) {
        return result;
      }
    }
    return onUnknownFailure(e);
  } on FormatException catch (e) {
    // This is not specific to Dio and can be thrown when calling jsonDecode with an invalid JSON String.
    return onDeserializationFailure(e.message);
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
}
