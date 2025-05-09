import 'package:flutter/foundation.dart';

@pragma('vm:platform-const-if', !kDebugMode)
bool get isWindows =>
    defaultTargetPlatform == TargetPlatform.windows && !kIsWeb;

@pragma('vm:platform-const-if', !kDebugMode)
bool get isLinux => defaultTargetPlatform == TargetPlatform.linux && !kIsWeb;

@pragma('vm:platform-const-if', !kDebugMode)
bool get isMacOS => defaultTargetPlatform == TargetPlatform.macOS && !kIsWeb;

@pragma('vm:platform-const-if', !kDebugMode)
bool get isDesktop =>
    (defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows) &&
    !kIsWeb;

enum DesktopPlatform { linux, macOS, windows }

DesktopPlatform get currentDesktopPlatform {
  return switch (defaultTargetPlatform) {
    TargetPlatform.linux => DesktopPlatform.linux,
    TargetPlatform.macOS => DesktopPlatform.macOS,
    TargetPlatform.windows => DesktopPlatform.windows,
    _ =>
      throw UnsupportedError(
        'Unsupported platform: ${defaultTargetPlatform.name}',
      ),
  };
}
