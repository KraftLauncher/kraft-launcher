import 'package:kraft_launcher/bootstrap.dart';
import 'package:logging/logging.dart';

/// Development config entry point.
/// Launch with `flutter run --target lib/main_development.dart`.
Future<void> main() async {
  Logger.root.level = Level.ALL;

  await bootstrap();
}
