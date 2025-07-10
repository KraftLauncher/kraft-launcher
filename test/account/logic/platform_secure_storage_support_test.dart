import 'package:kraft_launcher/account/data/linux_secret_service/linux_secret_service_checker.dart';
import 'package:kraft_launcher/account/logic/platform_secure_storage_support.dart';
import 'package:kraft_launcher/common/logic/platform_check.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../common/helpers/platform_utils.dart';

void main() {
  late PlatformSecureStorageSupport secureStorageSupport;
  late _MockLinuxSecretServiceChecker mockLinuxSecretServiceChecker;

  setUp(() {
    mockLinuxSecretServiceChecker = _MockLinuxSecretServiceChecker();
    secureStorageSupport = PlatformSecureStorageSupport(
      linuxSecretServiceChecker: mockLinuxSecretServiceChecker,
    );
  });

  test('returns true on ${DesktopPlatform.windows.name}', () async {
    await withPlatform(DesktopPlatform.windows, () async {
      expect(await secureStorageSupport.isSupported(), true);
    });
  });

  // NOTE: This test should be updated once the app is registered with Apple so
  // the app access to Apple keychain. There is already an issue so we can keep track
  // the progress. https://github.com/KraftLauncher/kraft-launcher/issues/2
  test(
    'returns false on ${DesktopPlatform.macOS.name} since app is not registered with Apple yet',
    () async {
      await withPlatform(DesktopPlatform.macOS, () async {
        expect(await secureStorageSupport.isSupported(), false);
      });
    },
  );

  group('linux', () {
    setUpAll(() {
      overrideCurrentDesktopPlatform = DesktopPlatform.linux;
    });

    tearDownAll(() {
      overrideCurrentDesktopPlatform = null;
    });

    void verifyLinuxSystemCallInteraction() {
      verify(
        () => mockLinuxSecretServiceChecker.isSecretServiceAvailable(),
      ).called(1);
      verifyNoMoreInteractions(mockLinuxSecretServiceChecker);
    }

    void mockSecretServiceAvailable({required bool secretServiceAvailable}) {
      when(
        () => mockLinuxSecretServiceChecker.isSecretServiceAvailable(),
      ).thenAnswer((_) async => secretServiceAvailable);
    }

    test(
      'returns true when $LinuxSecretServiceChecker reports available',
      () async {
        mockSecretServiceAvailable(secretServiceAvailable: true);

        expect(await secureStorageSupport.isSupported(), true);

        verifyLinuxSystemCallInteraction();
      },
    );

    test(
      'returns false when $LinuxSecretServiceChecker reports unavailable',
      () async {
        mockSecretServiceAvailable(secretServiceAvailable: false);

        expect(await secureStorageSupport.isSupported(), false);

        verifyLinuxSystemCallInteraction();
      },
    );

    test(
      'caches result from $LinuxSecretServiceChecker after first check',
      () async {
        mockSecretServiceAvailable(secretServiceAvailable: false);

        expect(secureStorageSupport.cachedLinuxSecretServiceAvailable, null);
        final firstResult = await secureStorageSupport.isSupported();
        expect(firstResult, false);

        verifyLinuxSystemCallInteraction();

        mockSecretServiceAvailable(secretServiceAvailable: true);

        expect(
          secureStorageSupport.cachedLinuxSecretServiceAvailable,
          firstResult,
        );

        final secondResult = await secureStorageSupport.isSupported();
        expect(secondResult, firstResult);

        verifyNever(
          () => mockLinuxSecretServiceChecker.isSecretServiceAvailable(),
        );
      },
    );
  });
}

class _MockLinuxSecretServiceChecker extends Mock
    implements LinuxSecretServiceChecker {}
