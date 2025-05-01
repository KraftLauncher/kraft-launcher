import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

abstract final class DioTestClient {
  static final instance = Dio();
}

class DioPostUriArguments<T> {
  DioPostUriArguments({
    required this.uri,
    required this.requestData,
    required this.options,
    required this.cancelToken,
    required this.onSendProgress,
    required this.onReceiveProgress,
  });

  final Uri uri;
  final T requestData;
  final Options? options;
  final CancelToken? cancelToken;
  final ProgressCallback? onSendProgress;
  final ProgressCallback? onReceiveProgress;
}

extension MockDioPostExt on MockDio {
  void mockPostUriSuccess<T>({
    required T? responseData,
    Uri? forUri,
    RequestOptions? requestOptions,
    int? statusCode,
    Headers? headers,
  }) {
    when(
      () => postUri<T>(
        forUri ?? any(),
        data: any(named: 'data'),
        cancelToken: any(named: 'cancelToken'),
        onReceiveProgress: any(named: 'onReceiveProgress'),
        onSendProgress: any(named: 'onSendProgress'),
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response<T>(
        requestOptions: requestOptions ?? RequestOptions(),
        data: responseData,
        statusCode: statusCode,
        headers: headers,
      ),
    );
  }

  void mockPostUriFailure<T>({
    required T? responseData,
    Uri? forUri,
    Object? error,
    RequestOptions? requestOptions,
    int? statusCode,
    Headers? headers,
    String? message,
    DioExceptionType? exceptionType,
    Exception? customException,
  }) {
    when(
      () => postUri<T>(
        forUri ?? any(),
        data: any(named: 'data'),
        cancelToken: any(named: 'cancelToken'),
        onReceiveProgress: any(named: 'onReceiveProgress'),
        onSendProgress: any(named: 'onSendProgress'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((_) async {
      final options = requestOptions ?? RequestOptions();
      if (customException != null) {
        throw customException;
      }
      return throw DioException(
        requestOptions: options,
        error: error,
        response: Response<T>(
          requestOptions: options,
          data: responseData,
          statusCode: statusCode,
          headers: headers,
        ),
        message: message,
        type: exceptionType ?? DioExceptionType.unknown,
      );
    });
  }

  // Req is the request body data
  // Res is the response body data
  DioPostUriArguments<Req> capturePostUriArguments<Req, Res>() {
    final verificationResult = verify(
      () => postUri<Res>(
        captureAny(),
        data: captureAny(named: 'data'),
        options: captureAny(named: 'options'),
        onSendProgress: captureAny(named: 'onSendProgress'),
        onReceiveProgress: captureAny(named: 'onReceiveProgress'),
        cancelToken: captureAny(named: 'cancelToken'),
      ),
    );
    verificationResult.called(1);
    final captured = verificationResult.captured;
    return DioPostUriArguments(
      uri: captured.first as Uri,
      requestData: captured[1] as Req,
      options: captured[2] as Options?,
      onSendProgress: captured[3] as ProgressCallback?,
      onReceiveProgress: captured[4] as ProgressCallback?,
      cancelToken: captured[5] as CancelToken?,
    );
  }
}

class DioGetUriArguments<T> {
  DioGetUriArguments({
    required this.uri,
    required this.requestData,
    required this.options,
    required this.cancelToken,
    required this.onReceiveProgress,
  });

  final Uri uri;
  final T? requestData;
  final Options? options;
  final CancelToken? cancelToken;
  final ProgressCallback? onReceiveProgress;
}

extension MockDioGetExt on MockDio {
  void mockGetUriSuccess<T>({
    required T? responseData,
    Uri? forUri,
    RequestOptions? requestOptions,
    int? statusCode,
    Headers? headers,
  }) {
    when(
      () => getUri<T>(
        forUri ?? any(),
        data: any(named: 'data'),
        cancelToken: any(named: 'cancelToken'),
        onReceiveProgress: any(named: 'onReceiveProgress'),
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response<T>(
        requestOptions: requestOptions ?? RequestOptions(),
        data: responseData,
        statusCode: statusCode,
        headers: headers,
      ),
    );
  }

  void mockGetUriFailure<T>({
    required T? responseData,
    Uri? forUri,
    Object? error,
    RequestOptions? requestOptions,
    int? statusCode,
    Headers? headers,
    String? message,
    DioExceptionType? exceptionType,
    Exception? customException,
  }) {
    when(
      () => getUri<T>(
        forUri ?? any(),
        data: any(named: 'data'),
        cancelToken: any(named: 'cancelToken'),
        onReceiveProgress: any(named: 'onReceiveProgress'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((_) async {
      final options = requestOptions ?? RequestOptions();
      if (customException != null) {
        throw customException;
      }
      return throw DioException(
        requestOptions: options,
        error: error,
        response: Response<T>(
          requestOptions: options,
          data: responseData,
          statusCode: statusCode,
          headers: headers,
        ),
        message: message,
        type: exceptionType ?? DioExceptionType.unknown,
      );
    });
  }

  // Req is the request body data
  // Res is the response body data
  DioGetUriArguments<Req> captureGetUriArguments<Req, Res>() {
    final verificationResult = verify(
      () => getUri<Res>(
        captureAny(),
        data: captureAny(named: 'data'),
        options: captureAny(named: 'options'),
        onReceiveProgress: captureAny(named: 'onReceiveProgress'),
        cancelToken: captureAny(named: 'cancelToken'),
      ),
    );
    verificationResult.called(1);
    final captured = verificationResult.captured;
    return DioGetUriArguments(
      uri: captured.first as Uri,
      requestData: captured[1] as Req?,
      options: captured[2] as Options?,
      onReceiveProgress: captured[3] as ProgressCallback?,
      cancelToken: captured[4] as CancelToken?,
    );
  }
}
