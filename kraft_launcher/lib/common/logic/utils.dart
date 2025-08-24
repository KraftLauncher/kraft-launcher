import 'package:clock/clock.dart';
import 'package:meta/meta.dart';

// For backward compatibility: Existing code already depends on this file, avoid breakage by moving and exporting.
export 'package:collection_utils/collection_utils.dart' show ListX;

// A wrapper used in copyWith functions, allowing to update a property to a null
// instead of using the current value.
@immutable
class Wrapped<T> {
  const Wrapped.value(this.value);

  final T value;
}

T requireNotNull<T>(T? value, {required String name}) {
  if (value == null) {
    throw StateError(
      'Expected $name to be not null at this state but was null.',
    );
  }
  return value;
}

DateTime expiresInToExpiresAt(int expiresIn) =>
    clock.now().add(Duration(seconds: expiresIn));

extension DateTimeExt on DateTime {
  bool get hasExpired => isBefore(clock.now());
}
