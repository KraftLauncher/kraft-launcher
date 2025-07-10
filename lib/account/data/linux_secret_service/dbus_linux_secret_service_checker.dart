import 'package:dbus/dbus.dart';
import 'package:kraft_launcher/account/data/linux_secret_service/linux_secret_service_checker.dart';
import 'package:kraft_launcher/common/constants/constants.dart';
import 'package:meta/meta.dart';

@visibleForTesting
typedef DBusClientFactory = DBusClient Function();

/// Checks for Secret Service availability on Linux using the
/// [`dbus`](https://pub.dev/packages/dbus) package which depends on
/// [Dart FFI](https://dart.dev/interop/c-interop).
///
/// See also: https://freedesktop.org/wiki/Software/dbus
final class DbusLinuxSecretServiceChecker implements LinuxSecretServiceChecker {
  DbusLinuxSecretServiceChecker({
    @visibleForTesting DBusClientFactory? clientFactory,
  }) : _clientFactory = clientFactory ?? DBusClient.session;

  final DBusClientFactory _clientFactory;

  @override
  Future<bool> isSecretServiceAvailable() async {
    final dbusClient = _clientFactory();
    try {
      final names = await dbusClient.listNames();
      final available = names.contains(
        DbusConstants.linuxDBusSecretServiceName,
      );
      return available;
    } finally {
      await dbusClient.close();
    }
  }
}
