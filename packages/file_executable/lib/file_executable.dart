/// Native chmod support to make files executable on Linux and macOS.
library;

export 'src/file_executable_stub.dart'
    if (dart.library.ffi) 'src/file_executable_real.dart';
