import 'package:flutter/material.dart';

extension ScaffoldMessengerExt on ScaffoldMessengerState {
  Future<ScaffoldFeatureController<SnackBar, SnackBarClosedReason>>
  showSnackBarText(String text, {SnackBarAction? snackBarAction}) async {
    clearSnackBars();
    return showSnackBar(SnackBar(content: Text(text), action: snackBarAction));
  }
}
