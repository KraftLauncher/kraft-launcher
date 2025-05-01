import 'dart:io';
import 'package:path/path.dart' as p;

Directory createTempTestDir() {
  return Directory.systemTemp.createTempSync();
}

File createFileInsideDir(Directory dir, {required String fileName}) {
  return File(p.join(dir.path, fileName))..createSync(recursive: true);
}
