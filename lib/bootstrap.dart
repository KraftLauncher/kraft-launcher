import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:kraft_launcher/app.dart';
import 'package:kraft_launcher/common/logic/app_data_paths.dart';
import 'package:kraft_launcher/common/logic/app_logger.dart';
import 'package:path_provider/path_provider.dart';

// TODO: Replace all occurrences of Enum.values.firstWhere(...) with Enum.byName(...)
//  because Enum.byName is a built-in, more efficient, and safer way to get enum
//  values by their name string. It avoids manual iteration and potential errors.
// TODO: Read: https://dart.dev/tools/linter-rules/avoid_slow_async_io, review all usages of file sync operations
// TODO: Avoid using @visibleForTesting for private fields
// TODO: Consider handling all errors/exceptions thrown from any fromJson()?

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appDataPaths = AppDataPaths(
    // TODO: Support portable mode, run in portable mode on debug-builds
    workingDirectory:
        kDebugMode
            ? (Directory('devWorkingDirectory')..createSync(recursive: true))
            : await getApplicationSupportDirectory(),
  );
  AppLogger.init();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.recordError(details.exceptionAsString());
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.recordError(error.toString());

    return false;
  };

  runApp(MainApp(appDataPaths: appDataPaths));
}
