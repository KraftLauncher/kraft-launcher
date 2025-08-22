import 'package:clock/clock.dart';
import 'package:mocktail/mocktail.dart';

extension WhenAsyncExt on When<Future<void>> {
  void thenDoNothing() => thenAnswer((_) async {});
}

extension WhenExt on When<void> {
  void thenDoNothing() => thenAnswer((_) {});
}

extension DateTimeExt on DateTime {
  DateTime trimSeconds() => DateTime(year, month, day, hour, minute);
  int get covertToExpiresIn {
    final now = clock.now();
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
