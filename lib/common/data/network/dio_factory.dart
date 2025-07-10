import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:kraft_launcher/common/constants/project_info_constants.dart';
import 'package:kraft_launcher/common/generated/pubspec.g.dart';
import 'package:talker_dio_logger/talker_dio_logger_interceptor.dart';
import 'package:talker_dio_logger/talker_dio_logger_settings.dart';

abstract final class DioFactory {
  static Dio newClient() {
    final dio = Dio();
    if (kDebugMode) {
      // These hosts get frequent requests; skip logging to avoid console spam.
      const ignoreHosts = <String>[
        'resources.download.minecraft.net',
        'libraries.minecraft.net',
        'piston-meta.mojang.com',
        'piston-data.mojang.com',
        'launchermeta.mojang.com',
      ];
      // TODO: Obscure the account tokens
      // TODO: If TalkerDioLogger was also used in production, then add tests for ignoreHosts
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
    dio.options.headers['User-Agent'] =
        '${ProjectInfoConstants.userAgentAppName}/${Pubspec.fullVersion} (${Platform.operatingSystem} ${Platform.operatingSystemVersion.split(' ')[1]}) ${ProjectInfoConstants.website}';
    return dio;
  }
}
