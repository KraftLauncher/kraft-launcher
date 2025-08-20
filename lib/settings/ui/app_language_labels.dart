import 'package:kraft_launcher/settings/logic/app_language.dart';

extension AppLanguageLabels on AppLanguage {
  String get label => switch (this) {
    AppLanguage.system => throw UnsupportedError(
      '${AppLanguage.system} does not have a hardcoded label. '
      'Callers (e.g., UI) should provide a localized label instead to support system language localization.',
    ),
    AppLanguage.en => 'English',
    AppLanguage.de => 'German',
    AppLanguage.ar => 'العربية',
    AppLanguage.zh => 'Mandarin Chinese',
  };
}
