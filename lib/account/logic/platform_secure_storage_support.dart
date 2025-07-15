import 'package:kraft_launcher/account/data/linux_secret_service/linux_secret_service_checker.dart';

import 'package:kraft_launcher/common/logic/platform_check.dart';
import 'package:meta/meta.dart';

class PlatformSecureStorageSupport {
  PlatformSecureStorageSupport({
    required LinuxSecretServiceChecker linuxSecretServiceChecker,
  }) : _linuxSecretServiceChecker = linuxSecretServiceChecker;

  final LinuxSecretServiceChecker _linuxSecretServiceChecker;

  @visibleForTesting
  bool? cachedLinuxSecretServiceAvailable;

  Future<bool> isSupported() async {
    return switch (currentDesktopPlatform) {
      DesktopPlatform.linux => await () async {
        final linuxCached = cachedLinuxSecretServiceAvailable;
        if (linuxCached != null) {
          return linuxCached;
        }

        final available =
            await _linuxSecretServiceChecker.isSecretServiceAvailable();
        cachedLinuxSecretServiceAvailable = available;
        return available;
      }(),
      // Accessing macOS keychain requires app registration with Apple, and the app
      // is not registered yet for now. Once the app is registered,
      // update this to true: https://github.com/KraftLauncher/kraft-launcher/issues/2
      DesktopPlatform.macOS => false,
      DesktopPlatform.windows => true,
    };
  }
}
