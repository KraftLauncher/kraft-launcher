@visibleForTesting
library;

import 'package:json_utils/json_utils.dart';
import 'package:meta/meta.dart';
import 'package:safe_http/src/api_client/http_response.dart';

@visibleForTesting
JsonHttpResponse dummyJsonHttpResponse({
  JsonMap? body,
  int? statusCode,
  Map<String, String>? headers,
  String? reasonPhrase,
}) => HttpResponse(
  body: body ?? {},
  statusCode: statusCode ?? 200,
  headers: headers ?? {},
  reasonPhrase: reasonPhrase ?? 'OK',
);

@visibleForTesting
HttpResponse<T> dummyHttpResponse<T>({
  required T body,
  int? statusCode,
  Map<String, String>? headers,
  String? reasonPhrase,
}) => HttpResponse(
  body: body,
  statusCode: statusCode ?? 200,
  headers: headers ?? {},
  reasonPhrase: reasonPhrase ?? 'OK',
);
