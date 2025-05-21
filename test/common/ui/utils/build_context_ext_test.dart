import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kraft_launcher/common/generated/l10n/app_localizations.dart';
import 'package:kraft_launcher/common/ui/utils/build_context_ext.dart';

void main() {
  testWidgets('loc returns $AppLocalizations if delegates are provided', (
    tester,
  ) async {
    const text = 'Example widget';
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Text(text),
        locale: Locale('en'),
      ),
    );

    final context = tester.element(find.text(text)) as BuildContext;
    expect(context.loc, isNotNull);
    expect(context.loc.cancel, 'Cancel');
  });

  testWidgets('loc throws $StateError if delegates are not provided', (
    tester,
  ) async {
    const text = 'Example widget';
    await tester.pumpWidget(const MaterialApp(home: Text(text)));

    final context = tester.element(find.text(text)) as BuildContext;
    expect(() => context.loc, throwsStateError);
  });

  testWidgets('theme and scaffoldMessenger returns correctly', (tester) async {
    BuildContext? buildContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            buildContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    if (buildContext == null) {
      fail('The $BuildContext should not be null');
    }
    expect(buildContext!.theme, Theme.of(buildContext!));
    expect(
      buildContext!.scaffoldMessenger,
      ScaffoldMessenger.of(buildContext!),
    );
  });

  for (final isDark in {true, false}) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    testWidgets(
      'isDark returns $isDark when $Brightness is ${brightness.name}',
      (tester) async {
        BuildContext? buildContext;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            builder: (context, child) {
              buildContext = context;
              return const SizedBox.shrink();
            },
          ),
        );
        if (buildContext == null) {
          fail('The $BuildContext should not be null');
        }
        expect(buildContext!.isDark, isDark);
      },
    );
  }
}
