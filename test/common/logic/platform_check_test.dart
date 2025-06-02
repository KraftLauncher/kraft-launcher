import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart' show TargetPlatformVariant;
import 'package:kraft_launcher/common/logic/platform_check.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  _testPlatformCheckGetter(
    'isLinux',
    getter: () => isLinux,
    platform: TargetPlatform.linux,
  );
  _testPlatformCheckGetter(
    'isMacOS',
    getter: () => isMacOS,
    platform: TargetPlatform.macOS,
  );
  _testPlatformCheckGetter(
    'isWindows',
    getter: () => isWindows,
    platform: TargetPlatform.windows,
  );

  final desktopPlatforms = TargetPlatformVariant.desktop().values;

  final nonDesktopPlatforms =
      TargetPlatform.values.toList()
        ..removeWhere((platform) => desktopPlatforms.contains(platform));

  group('isDesktop', () {
    test('returns true on desktop platforms', () {
      for (final desktopPlatform in desktopPlatforms) {
        debugDefaultTargetPlatformOverride = desktopPlatform;

        expect(isDesktop, true);
      }
    });

    test('returns false on non-desktop platforms', () {
      for (final nonDesktopPlatform in nonDesktopPlatforms) {
        debugDefaultTargetPlatformOverride = nonDesktopPlatform;

        expect(isDesktop, false);
      }
    });
  });

  group('currentDesktopPlatform', () {
    for (final desktopPlatform in desktopPlatforms) {
      test(
        'returns "$DesktopPlatform.${desktopPlatform.name}" on "${desktopPlatform.name}" target platform',
        () {
          debugDefaultTargetPlatformOverride = desktopPlatform;

          final expectedPlatform = switch (defaultTargetPlatform) {
            TargetPlatform.linux => DesktopPlatform.linux,
            TargetPlatform.macOS => DesktopPlatform.macOS,
            TargetPlatform.windows => DesktopPlatform.windows,
            _ =>
              throw UnsupportedError(
                'Unsupported platform ${defaultTargetPlatform.name}.',
              ),
          };
          expect(currentDesktopPlatform, expectedPlatform);
        },
      );
    }
    test('throws $UnsupportedError on non-desktop platforms', () {
      for (final nonDesktopPlatform in nonDesktopPlatforms) {
        debugDefaultTargetPlatformOverride = nonDesktopPlatform;

        expect(() => currentDesktopPlatform, throwsUnsupportedError);
      }
    });
  });
}

void _testPlatformCheckGetter(
  String getterName, {
  required bool Function() getter,
  required TargetPlatform platform,
}) {
  test('$getterName returns true on "${platform.name}" platform', () {
    debugDefaultTargetPlatformOverride = platform;

    expect(getter(), true);
  });
  test(
    '$getterName returns false on platform other than "${platform.name}"',
    () {
      final otherPlatforms = TargetPlatform.values.toList()..remove(platform);
      for (final otherPlatform in otherPlatforms) {
        debugDefaultTargetPlatformOverride = otherPlatform;

        expect(getter(), false);
      }
    },
  );
}
