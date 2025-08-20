/// A stub implementation to satisfy compilation of multi-platform packages that
/// depend on file_executable. This should never actually be created.
class FileExecutable {
  bool makeExecutable(String path) => throw UnsupportedError(
    'makeExecutable is not supported on the web, only supported on Linux and macOS.',
  );
}
