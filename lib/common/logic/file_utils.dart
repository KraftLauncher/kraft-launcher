import 'dart:io' show File;

import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

extension FileExt on File {
  MediaType get mediaType => MediaType.parse(
    lookupMimeType(path) ??
        (throw StateError('The mediaType is unknown for this file: $path')),
  );
}
