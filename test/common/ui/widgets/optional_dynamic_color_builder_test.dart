import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kraft_launcher/common/ui/widgets/optional_dynamic_color_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('calls builder with nulls when isEnabled is false', (
    tester,
  ) async {
    ColorScheme? receivedLight;
    ColorScheme? receivedDark;
    await tester.pumpWidget(
      MaterialApp(
        home: OptionalDynamicColorBuilder(
          isEnabled: false,
          builder: (light, dark) {
            receivedLight = light;
            receivedDark = dark;
            return const Text('Example Test');
          },
        ),
      ),
    );

    expect(receivedLight, isNull);
    expect(receivedDark, isNull);
    expect(find.byType(DynamicColorBuilder), findsNothing);
  });

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  testWidgets('uses $DynamicColorBuilder when isEnabled is true', (
    tester,
  ) async {
    // The widget DynamicColorBuilder prints to the debug console, use runZoned to run silently.
    await runZoned(
      () async {
        const accentColor = Colors.red;
        messenger.setMockMethodCallHandler(DynamicColorPlugin.channel, (
          methodCall,
        ) async {
          if (methodCall.method == DynamicColorPlugin.accentColorMethodName) {
            return accentColor.toARGB32();
          }
          return null;
        });

        ColorScheme? receivedLight;
        ColorScheme? receivedDark;

        await tester.pumpWidget(
          MaterialApp(
            home: OptionalDynamicColorBuilder(
              isEnabled: true,
              builder: (light, dark) {
                receivedLight = light;
                receivedDark = dark;
                return const Text('Example Test');
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(DynamicColorBuilder), findsOne);
        expect(
          receivedDark,
          ColorScheme.fromSeed(
            seedColor: accentColor,
            brightness: Brightness.dark,
          ),
        );
        expect(
          receivedLight,
          ColorScheme.fromSeed(
            seedColor: accentColor,
            brightness: Brightness.light,
          ),
        );
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) {
          // Silenced
        },
      ),
    );
  });

  tearDown(
    () =>
        messenger.setMockMessageHandler(DynamicColorPlugin.channel.name, null),
  );
}
