@internal
library;

import 'package:meta/meta.dart';

bool listEquals<T>(List<T> list1, List<T> list2) {
  if (identical(list1, list2)) {
    return true;
  }
  if (list1.length != list2.length) {
    return false;
  }

  for (var i = 0; i < list1.length; i++) {
    final e1 = list1[i];
    final e2 = list2[i];
    if (e1 != e2) {
      return false;
    }
  }
  return true;
}
