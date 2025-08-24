@internal
library;

// ignore_for_file: prefer_final_locals, always_put_control_body_on_new_line

import 'dart:convert' show Encoding;

import 'package:http/http.dart';
import 'package:meta/meta.dart';

/// Exposes the internal method `_sendUnstreamed` from `package:http`.
@internal
extension SendUnstreamedInternal on Client {
  /// Sends a non-streaming [Request] and returns a non-streaming [Response].
  ///
  /// This method is a copy of the internal method from `package:http`:
  /// https://github.com/dart-lang/http/blob/6656f15e88e68f6cafa2a7bbffa37fd6ac2dd33a/pkgs/http/lib/src/base_client.dart#L73-L94
  //
  // Note for project maintainers: Keep this method as close as possible to the upstream version
  // to simplify comparison and future updates. Only formatting changes are allowed;
  // ignore lint warnings instead of modifying the code.
  @internal
  Future<Response> sendUnstreamed(
    String method,
    Uri url,
    Map<String, String>? headers, [
    Object? body,
    Encoding? encoding,
  ]) async {
    var request = Request(method, url);

    if (headers != null) request.headers.addAll(headers);
    if (encoding != null) request.encoding = encoding;
    if (body != null) {
      if (body is String) {
        request.body = body;
      } else if (body is List) {
        request.bodyBytes = body.cast<int>();
      } else if (body is Map) {
        request.bodyFields = body.cast<String, String>();
      } else {
        throw ArgumentError('Invalid request body "$body".');
      }
    }

    return Response.fromStream(await send(request));
  }
}
