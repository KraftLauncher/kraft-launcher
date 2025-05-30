import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kraft_launcher/account/data/minecraft_account/secure_storage/secure_account_data.dart';
import 'package:kraft_launcher/account/data/minecraft_account/secure_storage/secure_account_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

void main() {
  late SecureAccountStorage secureAccountStorage;
  late _MockFlutterSecureStorage mockFlutterSecureStorage;

  setUp(() {
    mockFlutterSecureStorage = _MockFlutterSecureStorage();
    secureAccountStorage = SecureAccountStorage(
      flutterSecureStorage: mockFlutterSecureStorage,
    );
  });

  const dummyAccountId = 'dummy_account_id';

  void mockRead({required String key, required String? value}) {
    when(
      () => mockFlutterSecureStorage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => value);
  }

  String storageKeyByAccountId(String accountId) => 'account_$accountId';

  group('read', () {
    test('returns null if data not found in storage', () async {
      const accountId = dummyAccountId;
      final storageKey = storageKeyByAccountId(accountId);

      mockRead(key: storageKey, value: null);

      expect(await secureAccountStorage.read(accountId), null);

      verify(() => mockFlutterSecureStorage.read(key: storageKey)).called(1);
      verifyNoMoreInteractions(mockFlutterSecureStorage);
    });

    test('returns stored $SecureAccountData if present', () async {
      const storedData = SecureAccountData(
        microsoftRefreshToken: 'example-microsoft-refresh-token',
        minecraftAccessToken: 'example-minecraft-access-token',
      );

      const accountId = dummyAccountId;
      final storageKey = storageKeyByAccountId(accountId);

      mockRead(key: storageKey, value: jsonEncode(storedData.toJson()));

      final retrievedData = await secureAccountStorage.read(accountId);

      expect(retrievedData, storedData);
      expect(retrievedData?.toJson(), storedData.toJson());

      verify(() => mockFlutterSecureStorage.read(key: storageKey)).called(1);
      verifyNoMoreInteractions(mockFlutterSecureStorage);
    });
  });
  group('delete', () {
    test('calls $FlutterSecureStorage.delete with correct key', () async {
      const accountId = dummyAccountId;
      final storageKey = storageKeyByAccountId(accountId);

      when(
        () => mockFlutterSecureStorage.delete(key: storageKey),
      ).thenAnswer((_) async {});

      await secureAccountStorage.delete(accountId);

      verify(() => mockFlutterSecureStorage.delete(key: storageKey)).called(1);
      verifyNoMoreInteractions(mockFlutterSecureStorage);
    });
  });
  group('write', () {
    test('calls $FlutterSecureStorage.write with correct key', () async {
      const accountId = dummyAccountId;
      final storageKey = storageKeyByAccountId(accountId);

      const data = SecureAccountData(
        microsoftRefreshToken: 'example-microsoft-refresh-token',
        minecraftAccessToken: 'example-minecraft-access-token',
      );

      final value = jsonEncode(data.toJson());

      when(
        () => mockFlutterSecureStorage.write(key: storageKey, value: value),
      ).thenAnswer((_) async {});

      await secureAccountStorage.write(accountId, data);

      verify(
        () => mockFlutterSecureStorage.write(key: storageKey, value: value),
      ).called(1);
      verifyNoMoreInteractions(mockFlutterSecureStorage);
    });
  });
}

class _MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}
