// We avoid starting processes (using [Process]) whenever possible for performance,
// sandbox and portability reasons (in case dbus-command not available)
@Deprecated(
  'This is not used anywhere. it is available as a backup/fallback '
  'in case the dbus package is no longer a dependency.',
)
library;

import 'dart:io' show Process;

import 'package:kraft_launcher/account/data/linux_secret_service/linux_secret_service_checker.dart';
import 'package:kraft_launcher/common/constants/constants.dart';

/// Checks for Secret Service availability on Linux using the `dbus-send` command.
///
/// See: https://dbus.freedesktop.org/doc/dbus-send.1.html
class DbusCommandLinuxSecretServiceChecker
    implements LinuxSecretServiceChecker {
  @override
  Future<bool> isSecretServiceAvailable() async {
    final result = await Process.run('dbus-send', [
      '--session',
      '--dest=org.freedesktop.DBus',
      '--type=method_call',
      '--print-reply',
      '/org/freedesktop/DBus',
      'org.freedesktop.DBus.ListNames',
    ]);
    if (result.exitCode != 0) {
      throw Exception(
        'Runtime error while checking whether Secret Service (libsecret backend) is available on this Linux OS: ${result.stderr}',
      );
    }
    final secretServiceAvailable = (result.stdout as String).contains(
      DbusConstants.linuxDBusSecretServiceName,
    );
    return secretServiceAvailable;
  }
}
