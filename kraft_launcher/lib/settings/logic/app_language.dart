enum AppLanguage {
  system(localeCode: ''),
  en(localeCode: 'en'),
  de(localeCode: 'de'),
  ar(localeCode: 'ar'),
  zh(localeCode: 'zh');

  const AppLanguage({required this.localeCode});

  final String localeCode;
}
