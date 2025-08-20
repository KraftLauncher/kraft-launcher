import 'package:json_utils/json_utils.dart';
import 'package:meta/meta.dart';

typedef JsonHttpResponse = HttpResponse<JsonMap>;
typedef StringHttpResponse = HttpResponse<String>;

@immutable
class HttpResponse<T> {
  const HttpResponse({
    required this.body,
    required this.statusCode,
    required this.headers,
    required this.reasonPhrase,
  });

  final T body;
  final int statusCode;
  final Map<String, String> headers;
  final String? reasonPhrase;

  @override
  String toString() =>
      'HttpResponse<$T>(statusCode: $statusCode, body: $body, headers: $headers, reasonPhrase: $reasonPhrase)';
}
