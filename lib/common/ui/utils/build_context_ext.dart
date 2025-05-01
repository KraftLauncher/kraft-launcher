import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';

extension BuildContextExt on BuildContext {
  AppLocalizations get loc =>
      AppLocalizations.of(this) ??
      (throw StateError(
        'Could not find the localization delegate of the app. Please provide it in the widget app.',
      ));

  ThemeData get theme => Theme.of(this);
  ScaffoldMessengerState get scaffoldMessenger => ScaffoldMessenger.of(this);
}
