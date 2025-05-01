import 'dart:io';

import 'package:path/path.dart' as p;

class AppDataPaths {
  AppDataPaths({required this.workingDirectory});

  static late AppDataPaths instance;

  final Directory workingDirectory;

  File get accounts => File(p.join(workingDirectory.path, 'accounts.json'));

  File get settings => File(p.join(workingDirectory.path, 'settings.json'));
}
