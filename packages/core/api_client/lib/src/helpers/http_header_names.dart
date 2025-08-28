/// Provides standard HTTP header names.
///
/// Copied from `dart:io` to stay independent of `dart:io` and allow usage
/// on non-IO platforms.
abstract final class HttpHeaderNames {
  static const accept = 'accept';
  static const acceptCharset = 'accept-charset';
  static const acceptEncoding = 'accept-encoding';
  static const acceptLanguage = 'accept-language';
  static const acceptRanges = 'accept-ranges';
  static const accessControlAllowCredentials =
      'access-control-allow-credentials';
  static const accessControlAllowHeaders = 'access-control-allow-headers';
  static const accessControlAllowMethods = 'access-control-allow-methods';
  static const accessControlAllowOrigin = 'access-control-allow-origin';
  static const accessControlExposeHeaders = 'access-control-expose-headers';
  static const accessControlMaxAge = 'access-control-max-age';
  static const accessControlRequestHeaders = 'access-control-request-headers';
  static const accessControlRequestMethod = 'access-control-request-method';
  static const age = 'age';
  static const allow = 'allow';
  static const authorization = 'authorization';
  static const cacheControl = 'cache-control';
  static const connection = 'connection';
  static const contentEncoding = 'content-encoding';
  static const contentLanguage = 'content-language';
  static const contentLength = 'content-length';
  static const contentLocation = 'content-location';
  static const contentMD5 = 'content-md5';
  static const contentRange = 'content-range';
  static const contentType = 'content-type';
  static const contentDisposition = 'content-disposition';
  static const date = 'date';
  static const etag = 'etag';
  static const expect = 'expect';
  static const expires = 'expires';
  static const from = 'from';
  static const host = 'host';
  static const ifMatch = 'if-match';
  static const ifModifiedSince = 'if-modified-since';
  static const ifNoneMatch = 'if-none-match';
  static const ifRange = 'if-range';
  static const ifUnmodifiedSince = 'if-unmodified-since';
  static const lastModified = 'last-modified';
  static const location = 'location';
  static const maxForwards = 'max-forwards';
  static const pragma = 'pragma';
  static const proxyAuthenticate = 'proxy-authenticate';
  static const proxyAuthorization = 'proxy-authorization';
  static const range = 'range';
  static const referer = 'referer';
  static const retryAfter = 'retry-after';
  static const server = 'server';
  static const te = 'te';
  static const trailer = 'trailer';
  static const transferEncoding = 'transfer-encoding';
  static const upgrade = 'upgrade';
  static const userAgent = 'user-agent';
  static const vary = 'vary';
  static const via = 'via';
  static const warning = 'warning';
  static const wwwAuthenticate = 'www-authenticate';
}
