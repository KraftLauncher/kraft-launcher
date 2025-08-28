import 'package:api_client/api_client.dart'
    show HttpHeaderNames, HttpStatusCodes, HttpStatusRanges;
import 'package:result/result.dart' show BaseFailure;

/// Maps an HTTP error response to a domain-level failure using the
/// app’s standard status code handling.
///
/// This function is tailored to the requirements of this app and
/// may not be applicable in other contexts.
///
/// Callbacks must be provided for the status codes you want to map.
/// Any response not explicitly handled will be passed to [orElse].
///
/// The optional [override] allows custom handling. If returned value is
/// non-null, that failure is returned immediately; otherwise, mapping
/// proceeds using the standard logic.
F mapHttpStatusToFailure<F extends BaseFailure>({
  required int statusCode,
  required Map<String, String> headers,
  required F Function() onTooManyRequests,
  required F Function()? onUnauthorized,
  required F Function(int? retryAfterInSeconds) onServiceUnavailable,
  required F Function() onInternalServerError,
  required F? Function()? override,
  required F Function() orElse,
}) {
  final overrideFailure = override?.call();

  if (overrideFailure != null) {
    return overrideFailure;
  }

  if (statusCode == HttpStatusCodes.tooManyRequests) {
    return onTooManyRequests();
  }

  if (statusCode == HttpStatusCodes.unauthorized && onUnauthorized != null) {
    return onUnauthorized.call();
  }

  if (statusCode == HttpStatusCodes.serviceUnavailable) {
    final retryAfterHeader = headers[HttpHeaderNames.retryAfter];
    return onServiceUnavailable(
      retryAfterHeader != null ? int.tryParse(retryAfterHeader) : null,
    );
  }

  if (HttpStatusRanges.isIn5xx(statusCode)) {
    return onInternalServerError();
  }

  return orElse();
}
