import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:talker_dio_logger/talker_dio_logger_interceptor.dart';
import 'package:talker_dio_logger/talker_dio_logger_settings.dart';

abstract final class DioClient {
  static Dio _instance = _createDio();
  static Dio get instance => _instance;

  /// Allows overriding the instance for testing.
  /// Pass `null` to restore the default instance.
  @visibleForTesting
  static set instance(Dio? newInstance) =>
      _instance = newInstance ?? _createDio();

  static Dio _createDio() {
    final dio = Dio();
    if (kDebugMode) {
      // These hosts get frequent requests; skip logging to avoid console spam.
      const ignoreHosts = <String>[
        'resources.download.minecraft.net',
        'piston-meta.mojang.com',
        'piston-data.mojang.com',
        'launchermeta.mojang.com',
      ];
      dio.interceptors.add(
        TalkerDioLogger(
          settings: TalkerDioLoggerSettings(
            printRequestHeaders: true,
            printResponseHeaders: true,
            requestFilter: (options) {
              if (ignoreHosts.contains(options.uri.host)) {
                return false;
              }
              return true;
            },
            responseFilter: (response) {
              if (ignoreHosts.contains(response.requestOptions.uri.host)) {
                return false;
              }
              return true;
            },
          ),
        ),
      );
    }
    return dio;
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
