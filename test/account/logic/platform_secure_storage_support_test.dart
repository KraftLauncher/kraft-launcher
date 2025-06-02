import 'package:dbus/dbus.dart';
import 'package:kraft_launcher/account/logic/platform_secure_storage_support.dart';
import 'package:kraft_launcher/common/logic/platform_check.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../common/helpers/platform_utils.dart';

void main() {
  late PlatformSecureStorageSupport secureStorageSupport;
  late _MockDBusClient mockDBusClient;

  setUp(() {
    mockDBusClient = _MockDBusClient();
    secureStorageSupport = PlatformSecureStorageSupport(
      linuxDBusClientFactory: () => mockDBusClient,
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
    setUp(() {
      when(() => mockDBusClient.close()).thenAnswer((_) async {});
    });

    setUpAll(() {
      overrideCurrentDesktopPlatform = DesktopPlatform.linux;
    });

    tearDownAll(() {
      overrideCurrentDesktopPlatform = null;
    });

    void verifyDBusInteractions() {
      verifyInOrder([
        () => mockDBusClient.listNames(),
        () => mockDBusClient.close(),
      ]);
      verifyNoMoreInteractions(mockDBusClient);
    }

    void mockSecretServiceSupported({required bool secretServiceAvailable}) {
      when(() => mockDBusClient.listNames()).thenAnswer(
        (_) async => secretServiceAvailable ? ['org.freedesktop.secrets'] : [],
      );
    }

    test('returns true when Secret Service is available', () async {
      mockSecretServiceSupported(secretServiceAvailable: true);

      expect(await secureStorageSupport.isSupported(), true);

      verifyDBusInteractions();
    });

    test('returns false when Secret Service is not available', () async {
      mockSecretServiceSupported(secretServiceAvailable: false);

      expect(await secureStorageSupport.isSupported(), false);

      verifyDBusInteractions();
    });

    test('caches DBus call result after first isSupported check', () async {
      mockSecretServiceSupported(secretServiceAvailable: false);

      expect(secureStorageSupport.cachedLinuxSecretServiceAvailable, null);
      final firstResult = await secureStorageSupport.isSupported();
      expect(firstResult, false);

      verifyDBusInteractions();

      mockSecretServiceSupported(secretServiceAvailable: true);

      expect(
        secureStorageSupport.cachedLinuxSecretServiceAvailable,
        firstResult,
      );

      final secondResult = await secureStorageSupport.isSupported();
      expect(secondResult, firstResult);

      verifyNever(() => mockDBusClient.listNames());
      verifyNever(() => mockDBusClient.close());
    });
  });
}

class _MockDBusClient extends Mock implements DBusClient {}
