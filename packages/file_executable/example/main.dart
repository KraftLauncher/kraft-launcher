import 'dart:io';

import 'package:file_executable/file_executable.dart';

void main() {
  if (!Platform.isLinux && !Platform.isMacOS) {
    stderr.writeln('❌ This package only supports Linux and macOS.');
    exit(1);
  }

  _run();
}

void _run() {
  stdout.write('Enter the path to the file to make it executable: ');
  final input = stdin.readLineSync()?.trim();

  if (input == null || input.trim().isEmpty) {
    stderr.writeln('❌ No input provided.');
    exit(1);
  }

  final file = File(input);
  if (!file.existsSync()) {
    stderr.writeln('❌ File does not exist: $input');
    exit(1);
  }

  final success = FileExecutable().makeExecutable(file.path);
  if (!success) {
    stderr.writeln('❌ Failed to make the file executable.');
    exit(1);
  }

  print('✅ The file is now executable: ${file.path}');
}
