import 'dart:io';
import 'package:kraft_launcher/settings/data/settings.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

// A test to ensure all localizations are added to the AppLanguage enum.

final _localizationsDir = Directory('l10n');
const _localizationFilePrefix = 'app_'; // E.g, app_en.arb

void main() {
  test(
    'Localizations matches AppLanguage.values to support in-app language settings',
    () async {
      final supportedLanguages =
          AppLanguage.values.toList()
            ..removeWhere((language) => language == AppLanguage.system);

      final localizationFiles =
          await _localizationsDir
              .list()
              .where(
                (fileSystemEntity) =>
                    fileSystemEntity is File &&
                    p.extension(fileSystemEntity.path) == '.arb',
              )
              .toList();

      expect(localizationFiles.length, supportedLanguages.length);

      final detectedLanguagesFromFiles = <AppLanguage>{
        ...localizationFiles.map(
          (arbFile) => supportedLanguages.firstWhere(
            (language) =>
                language.localeCode ==
                p
                    .basenameWithoutExtension(arbFile.path)
                    .replaceFirst(_localizationFilePrefix, ''),
          ),
        ),
      };
      expect(detectedLanguagesFromFiles, <AppLanguage>{...supportedLanguages});
    },
  );
}
