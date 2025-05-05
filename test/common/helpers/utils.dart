import 'dart:io';

import 'package:mocktail/mocktail.dart';

extension WhenAsyncExt on When<Future<void>> {
  void thenDoNothing() => thenAnswer((_) async {});
}

extension WhenExt on When<void> {
  void thenDoNothing() => thenAnswer((_) {});
}

Future<bool> isPortOpen(
  String host,
  int port, {
  Duration timeout = const Duration(seconds: 1),
}) async {
  try {
    final socket = await Socket.connect(host, port, timeout: timeout);
    socket.destroy();
    return true;
  } on Exception catch (_) {
    return false;
  }
}

extension DateTimeExt on DateTime {
  DateTime trimSeconds() => DateTime(year, month, day, hour, minute);
  int get covertToExpiresIn {
    final now = DateTime.now();
    final normalizedNow = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
      now.second,
    );
    return difference(normalizedNow).inSeconds;
  }
}
