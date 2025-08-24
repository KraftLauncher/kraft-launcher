import 'package:http/http.dart' show MultipartFile;

// Why [MultipartFile] from the `package:http` is used as part of this API:
//
// * Responsibility separation: The API client should focus on constructing and sending HTTP requests,
//   not on how or where the file data is sourced (e.g., disk, memory, network).
//   Accepting a file path directly would force the API client to handle file IO, which breaks this separation.
//
// * Memory efficiency: Accepting raw bytes ([List<int>] or [Uint8List]) requires loading
//   the entire file into memory before uploading, which is impractical for large files.
//
// * Stream<List<int>> provides memory efficiency by streaming file data,
//   but requires additional metadata (file name, length, content type) to be managed separately,
//   complicating the API surface and increasing risk of misuse.
//
// * [http.MultipartFile] conveniently encapsulates the file data stream along with its metadata,
//   abstracts away the source of the data, and integrates seamlessly with HTTP multipart requests.
//   This results in a clean, expressive, and performance-efficient API boundary.
//
// For these reasons, exposing [MultipartFile] from the `http` package strikes the right balance
// between abstraction, performance, and ease of use for file uploads.
export 'package:http/http.dart' show MultipartFile;

// Required to allow consumers to create a [MultipartFile] with a content type set,
// without depending on the http_parser package.
// ignore: depend_on_referenced_packages
export 'package:http_parser/http_parser.dart' show MediaType;

class MultipartBody {
  MultipartBody({required this.fields, required this.files});

  factory MultipartBody.empty() => MultipartBody(fields: {}, files: []);

  /// Key-value pairs for plain text fields.
  ///
  /// Example:
  ///
  /// ```dart
  /// {
  ///   "variant": "classic",
  /// }
  /// ```
  final Map<String, String> fields;

  /// List of file fields.
  final List<MultipartFile> files;
}
