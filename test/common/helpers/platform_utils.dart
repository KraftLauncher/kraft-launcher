import 'package:flutter/foundation.dart';
import 'package:kraft_launcher/common/logic/platform_check.dart';

@visibleForTesting
set overrideCurrentDesktopPlatform(DesktopPlatform? value) =>
    debugDefaultTargetPlatformOverride = switch (value) {
      DesktopPlatform.linux => TargetPlatform.linux,
      DesktopPlatform.macOS => TargetPlatform.macOS,
      DesktopPlatform.windows => TargetPlatform.windows,
      null => null,
    };

Future<T> withPlatform<T>(
  DesktopPlatform platform,
  Future<T> Function() body,
) async {
  final previous = debugDefaultTargetPlatformOverride;
  overrideCurrentDesktopPlatform = platform;
  try {
    return await body();
  } finally {
    debugDefaultTargetPlatformOverride = previous;
  }
}
