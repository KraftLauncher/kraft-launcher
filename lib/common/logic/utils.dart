import 'dart:math';

import 'package:meta/meta.dart';

// A wrapper used in copyWith functions, allowing to update a property to a null
// instead of using the current value.
@immutable
class Wrapped<T> {
  const Wrapped.value(this.value);

  final T value;
}

extension ListX<T> on List<T> {
  /// Returns the new index to focus on after an item is removed from a list.
  ///
  /// If the removed index is still within bounds, returns it (the next item takes its place).
  /// If the removed item was the last, returns the previous index if available.
  /// Returns `null` if the list is empty.
  ///
  /// NOTE: This should be called on the new list with the removal, not the current list.
  int? getNewIndexAfterRemoval(int removedIndex) {
    if (isEmpty) {
      return null;
    }
    if (removedIndex < length) {
      return removedIndex;
    }
    if (removedIndex - 1 >= 0) {
      return removedIndex - 1;
    }
    return null;
  }

  int? indexWhereOrNull(bool Function(T item) test) {
    final index = indexWhere(test);
    return index == -1 ? null : index;
  }

  T get randomElement => this[Random().nextInt(length)];
}

T requireNotNull<T>(T? value, {required String name}) {
  if (value == null) {
    throw Exception(
      'Expected $name to be not null at this state but was null.',
    );
  }
  return value;
}

DateTime expiresInToExpiresAt(int expiresIn) =>
    DateTime.now().add(Duration(seconds: expiresIn));
