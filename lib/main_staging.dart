import 'package:kraft_launcher/bootstrap.dart';
import 'package:logging/logging.dart';

/// Staging config entry point.
/// Launch with `flutter run --target lib/main_staging.dart`.
Future<void> main() async {
  Logger.root.level = Level.INFO;

  // TODO: Add crash analytics, consider: https://pub.dev/packages/sentry
  await bootstrap();
}
