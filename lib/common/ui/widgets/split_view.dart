import 'package:flutter/material.dart';

import '../utils/build_context_ext.dart';

/// A responsive layout with a primary pane (e.g. sidebar) and a secondary pane (e.g. content),
/// displayed side-by-side on large screens. This is not designed for small screens.
class SplitView extends StatelessWidget {
  const SplitView({
    super.key,
    required this.primaryPaneTitle,
    required this.primaryPane,
    required this.secondaryPane,
  });

  final String primaryPaneTitle;
  final Widget primaryPane;
  final Widget? secondaryPane;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 300,
        child: Material(
          color: context.theme.colorScheme.surfaceContainerLow,
          borderRadius: const BorderRadiusDirectional.only(
            topEnd: Radius.circular(14),
            bottomEnd: Radius.circular(14),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  primaryPaneTitle,
                  style: context.theme.textTheme.headlineMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: primaryPane,
              ),
            ],
          ),
        ),
      ),
      if (secondaryPane != null)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(50, 40, 16, 16),
            child: secondaryPane,
          ),
        ),
    ],
  );
}

class PrimaryTilePane extends StatelessWidget {
  const PrimaryTilePane({
    super.key,
    required this.selected,
    required this.title,
    required this.leading,
    this.trailing,
    required this.onTap,
    this.contentPadding,
  });

  final bool selected;
  final Widget title;
  final Widget leading;
  final Widget? trailing;
  final GestureTapCallback onTap;
  final EdgeInsets? contentPadding;

  BorderRadius get _borderRadius => BorderRadius.circular(12);

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    decoration: BoxDecoration(
      borderRadius: _borderRadius,
      color: selected ? context.theme.colorScheme.secondaryContainer : null,
    ),
    child: ListTile(
      title: title,
      leading: leading,
      shape: RoundedRectangleBorder(borderRadius: _borderRadius),
      tileColor: selected ? context.theme.colorScheme.secondaryContainer : null,
      onTap: onTap,
      selected: selected,
      selectedTileColor: Colors.transparent,
      selectedColor: context.theme.textTheme.bodyMedium!.color,
      contentPadding: contentPadding ?? const EdgeInsets.all(8),
      titleTextStyle: context.theme.textTheme.titleMedium,
      trailing: trailing,
    ),
  );

  // Previous implementation:
  // @override
  // Widget build(BuildContext context) => InkWell(
  //   highlightColor: Colors.transparent,
  //   onTap: onTap,
  //   customBorder: RoundedRectangleBorder(borderRadius: _borderRadius),
  //   child: AnimatedContainer(
  //     duration: const Duration(milliseconds: 200),
  //     decoration: BoxDecoration(
  //       borderRadius: _borderRadius,
  //       color: isSelected ? context.theme.colorScheme.secondaryContainer : null,
  //     ),
  //     height: 56,
  //     child: Row(
  //       children: <Widget>[
  //         const SizedBox(width: 16),
  //         leading,
  //         const SizedBox(width: 12),
  //         title,
  //       ],
  //     ),
  //   ),
  // );
}
