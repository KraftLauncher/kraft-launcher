import 'package:flutter/material.dart';

@immutable
class NavigationMenuItem {
  const NavigationMenuItem({
    required this.unselectedIcon,
    required this.selectedIcon,
    required this.label,
    required this.body,
    this.floatingActionButton,
  });
  final Widget unselectedIcon;
  final Widget selectedIcon;
  final String label;

  final Widget body;

  final Widget? floatingActionButton;
}

class ScaffoldWithTabs extends StatefulWidget {
  const ScaffoldWithTabs({
    super.key,
    required this.navigationMenuItems,
    required this.trailingItems,
    required this.defaultIndex,
  });

  final List<NavigationMenuItem> navigationMenuItems;
  final List<Widget> trailingItems;
  final int defaultIndex;

  @override
  State<ScaffoldWithTabs> createState() => _ScaffoldWithTabsState();
}

class _ScaffoldWithTabsState extends State<ScaffoldWithTabs> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.defaultIndex;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Row(
      children: [
        NavigationRail(
          labelType: NavigationRailLabelType.all,
          onDestinationSelected:
              (value) => setState(() => _selectedIndex = value),
          destinations:
              widget.navigationMenuItems
                  .map(
                    (e) => NavigationRailDestination(
                      icon: e.unselectedIcon,
                      label: Text(e.label),
                      selectedIcon: e.selectedIcon,
                    ),
                  )
                  .toList(),
          selectedIndex: _selectedIndex,
          trailing: Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: widget.trailingItems,
            ),
          ),
        ),
        Expanded(child: widget.navigationMenuItems[_selectedIndex].body),
      ],
    ),
    floatingActionButton:
        widget.navigationMenuItems[_selectedIndex].floatingActionButton,
  );
}
