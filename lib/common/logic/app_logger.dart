import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

abstract final class AppLogger {
  static final _logger = Logger('AppLogger');
  static final List<String> _logs = [];
  static List<String> get logs => List.unmodifiable(_logs);

  static void init() {
    Logger.root.level = Level.ALL;
    recordStackTraceAtLevel = Level.SEVERE;
    Logger.root.onRecord.listen((record) {
      final message = formatMessage(
        record.message,
        dateTime: record.time,
        level: record.level,
      );
      if (record.error != null) {
        // ignore: avoid_print
        print(record.stackTrace);
        _logs.add(
          formatMessage(
            'Stacktrace: \n${record.stackTrace}',
            dateTime: record.time,
            level: record.level,
          ),
        );
      }
      _logs.add(message);
      debugPrint(message);
    });
  }

  static void w(Object message, [Object? error, StackTrace? stackTrace]) =>
      _logger.warning(message, error, stackTrace);
  static void i(Object message, [Object? error, StackTrace? stackTrace]) =>
      _logger.info(message, error, stackTrace);
  static void e(Object message, [Object? error, StackTrace? stackTrace]) =>
      _logger.severe(message, error, stackTrace);

  @visibleForTesting
  static String formatMessage(
    String message, {
    required DateTime dateTime,
    required Level level,
  }) {
    final time = DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
    final formattedMessage = '[$time] ${level.name}: $message';
    return formattedMessage;
  }

  static void recordError(String error) {
    _logs.add(
      formatMessage(error, dateTime: DateTime.now(), level: Level.SEVERE),
    );
  }
}
