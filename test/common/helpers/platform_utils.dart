import 'package:flutter/foundation.dart';

Future<T> withPlatform<T>(
  TargetPlatform platform,
  Future<T> Function() body,
) async {
  final previous = debugDefaultTargetPlatformOverride;
  debugDefaultTargetPlatformOverride = platform;
  try {
    return await body();
  } finally {
    debugDefaultTargetPlatformOverride = previous;
  }
}
