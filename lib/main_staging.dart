import 'package:kraft_launcher/bootstrap.dart';

/// Staging config entry point.
/// Launch with `flutter run --target lib/main_staging.dart`.
Future<void> main() async {
  // TODO: Add crash analytics, consider: https://pub.dev/packages/sentry
  await bootstrap();
}
