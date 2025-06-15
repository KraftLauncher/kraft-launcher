void main() {
  // ignore: avoid_print
  print(
    'Remove minecraft_account_manager_test.dart file once tests of MinecraftAccountService are completed',
  );
}

// Tests for all functions that uses _transformExceptions
// void _transformExceptionCommonTests(
//   _MockMinecraftApi Function() mockMinecraftApi,
//   _MockMicrosoftAuthApi Function() mockMicrosoftAuthApi,
//   Future<void> Function() action,
// ) {
//   test(
//     'throws $MinecraftApiAccountManagerException on $MinecraftApiException',
//     () async {
//       final minecraftApiException = MinecraftApiException.tooManyRequests();
//       when(
//         () => mockMinecraftApi().fetchMinecraftProfile(any()),
//       ).thenAnswer((_) async => throw minecraftApiException);
//       await expectLater(
//         action(),
//         throwsA(
//           isA<MinecraftApiAccountManagerException>().having(
//             (e) => e.minecraftApiException,
//             'minecraftApiException',
//             equals(minecraftApiException),
//           ),
//         ),
//       );
//     },
//   );

//   test(
//     'throws $MicrosoftApiAccountManagerException on $MicrosoftAuthException',
//     () async {
//       final microsoftAuthException = MicrosoftAuthException.authCodeExpired();
//       when(
//         () => mockMicrosoftAuthApi().requestXboxLiveToken(any()),
//       ).thenAnswer((_) async => throw microsoftAuthException);
//       await expectLater(
//         action(),
//         throwsA(
//           isA<MicrosoftApiAccountManagerException>().having(
//             (e) => e.authApiException,
//             'microsoftAuthException',
//             equals(microsoftAuthException),
//           ),
//         ),
//       );
//     },
//   );

//   test('throws $UnknownAccountManagerException on $Exception', () async {
//     final exception = Exception('Hello, World!');
//     when(
//       () => mockMicrosoftAuthApi().requestXboxLiveToken(any()),
//     ).thenAnswer((_) async => throw exception);
//     await expectLater(
//       action(),
//       throwsA(
//         isA<UnknownAccountManagerException>().having(
//           (e) => e.message,
//           'message',
//           equals(exception.toString()),
//         ),
//       ),
//     );
//   });

//   test('rethrows $AccountManagerException when caught', () async {
//     final exception = AccountManagerException.unknown(
//       'Unknown',
//       StackTrace.current,
//     );

//     when(
//       () => mockMicrosoftAuthApi().requestXboxLiveToken(any()),
//     ).thenAnswer((_) async => throw exception);

//     await expectLater(
//       action(),
//       throwsA(
//         isA<UnknownAccountManagerException>().having(
//           (e) => e.message,
//           'message',
//           equals(exception.toString()),
//         ),
//       ),
//     );
//   });
// }
