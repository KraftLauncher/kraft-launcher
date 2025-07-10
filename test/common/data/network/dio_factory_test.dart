import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kraft_launcher/common/constants/project_info_constants.dart';
import 'package:kraft_launcher/common/data/network/dio_factory.dart';
import 'package:kraft_launcher/common/generated/pubspec.g.dart';
import 'package:talker_dio_logger/talker_dio_logger_interceptor.dart';

void main() {
  late Dio dio;

  setUp(() {
    dio = DioFactory.newClient();
  });

  test('instance adds $TalkerDioLogger in debug mode', () {
    if (kDebugMode) {
      final interceptors = dio.interceptors;
      expect(
        interceptors.any((i) => i is TalkerDioLogger),
        isTrue,
        reason: '$TalkerDioLogger should be added in debug mode',
      );
    }
  });

  test('adds "User-Agent" header to all requests', () {
    expect(
      dio.options.headers['User-Agent'],
      '${ProjectInfoConstants.userAgentAppName}/${Pubspec.fullVersion} (${Platform.operatingSystem} ${Platform.operatingSystemVersion.split(' ')[1]}) ${ProjectInfoConstants.website}',
    );
  });
}
