import 'package:kraft_launcher/bootstrap.dart';

/// Production config entry point.
/// Launch with `flutter run --target lib/main_production.dart`.
Future<void> main() async {
  // TODO: Add crash analytics, consider: https://pub.dev/packages/sentry
  await bootstrap();
}
