/// Checks if the Linux Secret Service (`org.freedesktop.secrets`) is available.
///
/// If available, it indicates that the [`libsecret`](https://wiki.gnome.org/Projects/Libsecret)
/// backend can be used for secure storage.
///
/// This service is used by the package
/// [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage).
///
/// See also:
///
/// * https://specifications.freedesktop.org/secret-service-spec/latest
/// * https://pub.dev/packages/flutter_secure_storage_linux, the platform-specific implementation
///   of `flutter_secure_storage` that depends on `libsecret` library.
abstract interface class LinuxSecretServiceChecker {
  Future<bool> isSecretServiceAvailable();
}
