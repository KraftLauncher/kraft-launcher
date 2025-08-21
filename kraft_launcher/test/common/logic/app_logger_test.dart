import 'package:intl/intl.dart';
import 'package:kraft_launcher/common/logic/app_logger.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

void main() {
  test('logs are empty by default', () {
    expect(AppLogger.logs, <String>[]);
  });

  test('formatMessage returns the formatted message correctly', () {
    const message = 'An example message';
    final dateTime = DateTime.now();
    const logLevel = Level.SEVERE;
    expect(
      AppLogger.formatMessage(message, dateTime: dateTime, level: logLevel),
      '[${DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime)}] ${logLevel.name}: $message',
    );
  });

  test('recordError adds to the log', () {
    const message = 'Example Message';
    AppLogger.recordError(message);
    expect(AppLogger.logs.isNotEmpty, true);
    expect(AppLogger.logs.any((log) => log.contains(message)), true);
  });
}
