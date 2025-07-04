import 'package:dio/dio.dart';
import 'package:kraft_launcher/common/logic/dio_helpers.dart';
import 'package:test/test.dart';

void main() {
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
