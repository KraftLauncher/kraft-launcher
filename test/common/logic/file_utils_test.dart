import 'dart:io';

import 'package:kraft_launcher/common/logic/file_utils.dart';
import 'package:test/test.dart';

void main() {
  test('mediaType returns correctly', () {
    expect(File('image.png').mediaType.mimeType, 'image/png');
    expect(File('image.jpg').mediaType.mimeType, 'image/jpeg');
    expect(File('image.jpeg').mediaType.mimeType, 'image/jpeg');
    expect(File('server.jar').mediaType.mimeType, 'application/java-archive');
    expect(File('file.zip').mediaType.mimeType, 'application/zip');
    expect(File('app.exe').mediaType.mimeType, 'application/x-msdownload');
    expect(File('script.sh').mediaType.mimeType, 'application/x-sh');
  });

  test('mediaType throws $StateError for unknown file types', () {
    final file = File('example.unknownextension');

    expect(() => file.mediaType, throwsA(isA<StateError>()));
  });
}
