import 'dart:io';

import 'package:mocktail/mocktail.dart';

extension MockAsync on When<Future<void>> {
  void thenDoNothing() => thenAnswer((_) async {});
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
