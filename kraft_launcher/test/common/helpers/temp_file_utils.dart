import 'dart:io';
import 'package:path/path.dart' as p;

// TODO: Avoid IO operations in unit tests, track all usages of createTempTestDir and createFileInsideDir. Use file package instead

Directory createTempTestDir() {
  return Directory.systemTemp.createTempSync();
}

File createFileInsideDir(Directory dir, {required String fileName}) {
  return File(p.join(dir.path, fileName))..createSync(recursive: true);
}
