enum AppLanguage {
  system(labelText: 'System', localeCode: ''),
  en(labelText: 'English', localeCode: 'en'),
  de(labelText: 'German', localeCode: 'de'),
  ar(labelText: 'العربية', localeCode: 'ar'),
  zh(labelText: 'Mandarin Chinese', localeCode: 'zh');

  const AppLanguage({required this.labelText, required this.localeCode});

  final String labelText;
  final String localeCode;
}
