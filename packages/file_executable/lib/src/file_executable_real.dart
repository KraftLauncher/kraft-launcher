import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

final DynamicLibrary _libc = Platform.isMacOS
    ? DynamicLibrary.open('/usr/lib/libc.dylib')
    : DynamicLibrary.open('libc.so.6');

final _chmod = _libc.lookupFunction<Int32 Function(Pointer<Utf8>, Uint32),
    int Function(Pointer<Utf8>, int)>('chmod');

class FileExecutable {
  /// Makes the file at [path] executable by setting mode 0o755 (rwxr-xr-x).
  ///
  /// Supported only on Linux and macOS.
  /// In debug builds, throws [UnsupportedError] if called on unsupported platforms.
  bool makeExecutable(String path) {
    assert(() {
      if (!Platform.isLinux && !Platform.isMacOS) {
        throw UnsupportedError(
          'makeExecutable is supported only on Linux and macOS. '
          'Called on: ${Platform.operatingSystem}',
        );
      }
      return true;
    }());

    final ptr = path.toNativeUtf8();

    try {
      final result = _chmod(ptr, 0x1ED); // 0o755
      return result == 0;
    } finally {
      calloc.free(ptr);
    }
  }
}
