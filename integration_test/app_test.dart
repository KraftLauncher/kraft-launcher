import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kraft_launcher/common/logic/platform_check.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:test/test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test(
    'uses correct application support directory on "${defaultTargetPlatform.name}" to avoid breaking changes',
    () async {
      final actualDir = await getApplicationSupportDirectory();

      final expectedDir = switch (currentDesktopPlatform) {
        DesktopPlatform.linux => p.join(
          Platform.environment['HOME']!,
          '.local',
          'share',
          'org.kraftlauncher.launcher',
        ),
        DesktopPlatform.macOS => p.join(
          Platform.environment['HOME']!,
          'Library',
          'Application Support',
          'org.kraftlauncher.launcher',
        ),
        DesktopPlatform.windows => p.join(
          Platform.environment['APPDATA']!,
          'org.kraftlauncher',
          'kraft_launcher',
        ),
      };

      expect(
        expectedDir,
        actualDir.path,
        reason:
            'The app support dir has been changed, this is considered a breaking change, please update the test or fix the issue.',
      );
    },
  );
}
