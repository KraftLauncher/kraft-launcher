import 'package:dbus/dbus.dart';
import 'package:kraft_launcher/account/data/linux_secret_service/dbus_linux_secret_service_checker.dart';
import 'package:kraft_launcher/common/logic/platform_check.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../common/helpers/platform_utils.dart';
import '../../../common/test_constants.dart';

void main() {
  late _MockDBusClient mockDBusClient;
  late DbusLinuxSecretServiceChecker checker;

  setUp(() {
    mockDBusClient = _MockDBusClient();
    checker = DbusLinuxSecretServiceChecker(
      clientFactory: () => mockDBusClient,
    );

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
      (_) async =>
          secretServiceAvailable
              ? ['org.freedesktop.secrets', TestConstants.anyString]
              : [TestConstants.anyString, TestConstants.anyString],
    );
  }

  test('returns true when Secret Service is available', () async {
    mockSecretServiceSupported(secretServiceAvailable: true);

    expect(await checker.isSecretServiceAvailable(), true);

    verifyDBusInteractions();
  });

  test('returns false when Secret Service is not available', () async {
    mockSecretServiceSupported(secretServiceAvailable: false);

    expect(await checker.isSecretServiceAvailable(), false);

    verifyDBusInteractions();
  });
}

class _MockDBusClient extends Mock implements DBusClient {}
