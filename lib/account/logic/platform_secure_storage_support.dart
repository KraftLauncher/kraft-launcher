import 'package:dbus/dbus.dart';
import 'package:flutter/foundation.dart';

import '../../common/logic/platform_check.dart';

// TODO: Show a message or indicator when the secure storage is unsupported on the current OS for the user in the UI?

class PlatformSecureStorageSupport {
  PlatformSecureStorageSupport({
    @visibleForTesting DBusClient Function()? linuxDBusClientFactory,
  }) : _linuxDBusClientFactory = linuxDBusClientFactory ?? DBusClient.session;

  @visibleForTesting
  bool? cachedLinuxSecretServiceAvailable;

  final DBusClient Function() _linuxDBusClientFactory;

  Future<bool> isSupported() async {
    return switch (currentDesktopPlatform) {
      DesktopPlatform.linux => await () async {
        final linuxCached = cachedLinuxSecretServiceAvailable;
        if (linuxCached != null) {
          return linuxCached;
        }
        final dbusClient = _linuxDBusClientFactory();
        try {
          final names = await dbusClient.listNames();
          final available = names.contains('org.freedesktop.secrets');
          cachedLinuxSecretServiceAvailable = available;
          return available;
        } finally {
          await dbusClient.close();
        }
      }(),
      // Accessing macOS keychain requires app registration with Apple, and the app
      // is not registered yet for now. Once the app is registered, update this to true: https://github.com/KraftLauncher/kraft-launcher/issues/2
      DesktopPlatform.macOS => false,
      DesktopPlatform.windows => true,
    };
  }
}

// Alternative solution without dbus package to detect on Linux:
//
// final result = await Process.run('dbus-send', [
//   '--session',
//   '--dest=org.freedesktop.DBus',
//   '--type=method_call',
//   '--print-reply',
//   '/org/freedesktop/DBus',
//   'org.freedesktop.DBus.ListNames',
// ]);
// if (result.exitCode != 0) {
//   throw Exception(
//     'Runtime error while checking whether Secret Service (libsecret backend) is available on this Linux OS: ${result.stderr}',
//   );
// }
// final secretServiceAvailable = (result.stdout as String).contains(
//   'org.freedesktop.secrets',
// );
