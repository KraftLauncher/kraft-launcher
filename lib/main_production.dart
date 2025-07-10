import 'package:kraft_launcher/bootstrap.dart';
import 'package:logging/logging.dart';

/// Production config entry point.
/// Launch with `flutter run --target lib/main_production.dart`.
Future<void> main() async {
  Logger.root.level = Level.WARNING;

  // TODO: Add crash analytics, consider: https://pub.dev/packages/sentry
  await bootstrap();
}
