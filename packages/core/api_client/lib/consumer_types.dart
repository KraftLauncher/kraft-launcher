/// Minimal set of types for consumers of API clients.
///
/// These types allow consumers to send requests and handle responses
/// without needing to depend directly on internal details.
library;

export 'package:api_client/api_client.dart'
    show
        HttpHeaderNames,
        HttpResponse,
        HttpStatusCodes,
        HttpStatusRanges,
        MediaType,
        MultipartFile;
export 'src/api_failures.dart';
