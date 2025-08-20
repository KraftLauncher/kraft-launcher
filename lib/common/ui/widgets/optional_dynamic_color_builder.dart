import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

class OptionalDynamicColorBuilder extends StatelessWidget {
  const OptionalDynamicColorBuilder({
    required this.isEnabled,
    required this.builder,
    super.key,
  });

  final bool isEnabled;
  final Widget Function(ColorScheme? lightDynamic, ColorScheme? darkDynamic)
  builder;

  @override
  Widget build(BuildContext context) {
    if (!isEnabled) {
      return builder(null, null);
    }
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) =>
          builder(lightDynamic, darkDynamic),
    );
  }
}
