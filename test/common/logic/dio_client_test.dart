import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kraft_launcher/common/logic/dio_client.dart';
import 'package:kraft_launcher/common/logic/json.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_dio_logger/talker_dio_logger_interceptor.dart';

import '../helpers/dio_utils.dart';

void main() {
  group(DioClient, () {
    tearDown(() => DioClient.instance = null);

    test('defaults to $Dio', () {
      expect(DioClient.instance, isA<Dio>());
    });

    test('sets the instance correctly', () {
      expect(DioClient.instance, isNot(isA<_FakeDio>()));

      DioClient.instance = _FakeDio();
      expect(DioClient.instance, isA<_FakeDio>());
    });

    test('passing null restores the default instance', () {
      final fake = _FakeDio();
      DioClient.instance = fake;
      expect(DioClient.instance, isA<_FakeDio>());

      DioClient.instance = null;
      expect(DioClient.instance, isA<Dio>());
    });

    test('delegates $Dio getUri call to assigned $Dio instance', () async {
      final mockDio = MockDio();
      DioClient.instance = mockDio;

      final uri = Uri.https('example.com');
      final expectedResponse = Response<JsonObject>(
        requestOptions: RequestOptions(),
        data: {'username': 'Alex'},
      );
      when(
        () => mockDio.getUri<JsonObject>(uri),
      ).thenAnswer((_) async => expectedResponse);

      final actualResponse = await DioClient.instance.getUri<JsonObject>(uri);
      expect(actualResponse.dataOrThrow, expectedResponse.data);
    });

    test('instance adds $TalkerDioLogger in debug mode', () {
      if (kDebugMode) {
        final interceptors = DioClient.instance.interceptors;
        expect(
          interceptors.any((i) => i is TalkerDioLogger),
          isTrue,
          reason: '$TalkerDioLogger should be added in debug mode',
        );
      }
    });
  });

  test('dataOrThrow returns data if not null', () {
    const data = 'json response';
    expect(
      Response(requestOptions: RequestOptions(), data: data).dataOrThrow,
      data,
    );
  });

  test('dataOrThrow throws $StateError if null', () {
    expect(
      () => Response(requestOptions: RequestOptions(), data: null).dataOrThrow,
      throwsStateError,
    );
  });

  test('userErrorMessage', () {
    const message = 'Example message';
    const response = true;
    expect(
      DioException(
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), data: response),
        message: message,
      ).userErrorMessage,
      'Response: $response.\n Message: $message',
    );
  });
}

class _FakeDio extends Fake implements Dio {}
