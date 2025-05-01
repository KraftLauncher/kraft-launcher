import 'package:flutter/material.dart';

import '../../../settings/data/settings.dart';
import '../../generated/l10n/app_localizations.dart';

extension HomeScreenTabExt on HomeScreenTab {
  String getLabel(AppLocalizations loc) => switch (this) {
    HomeScreenTab.news => loc.news,
    HomeScreenTab.profiles => loc.profiles,
    HomeScreenTab.accounts => loc.accounts,
    HomeScreenTab.settings => loc.settings,
  };
  IconData get selectedIconData => switch (this) {
    HomeScreenTab.news => Icons.article,
    HomeScreenTab.profiles => Icons.gamepad,
    HomeScreenTab.accounts => Icons.person,
    HomeScreenTab.settings => Icons.settings,
  };

  IconData get unselectedIconData => switch (this) {
    HomeScreenTab.news => Icons.article_outlined,
    HomeScreenTab.profiles => Icons.gamepad_outlined,
    HomeScreenTab.accounts => Icons.person_outline,
    HomeScreenTab.settings => Icons.settings,
  };
}
