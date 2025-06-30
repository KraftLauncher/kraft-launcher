import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:kraft_launcher/common/ui/utils/build_context_ext.dart';
import 'package:kraft_launcher/common/ui/widgets/split_view.dart';
import 'package:kraft_launcher/settings/ui/categories/about_settings_category.dart';
import 'package:kraft_launcher/settings/ui/categories/general_settings_category.dart';
import 'package:kraft_launcher/settings/ui/cubit/settings_cubit.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<SettingsCubit, SettingsState>(
    builder:
        (context, state) => SplitView(
          primaryPaneTitle: context.loc.settings,
          primaryPane: Column(
            children:
                SettingsCategory.values.map((category) {
                  final (title, iconData) = switch (category) {
                    SettingsCategory.general => (
                      context.loc.general,
                      Icons.settings_suggest,
                    ),
                    SettingsCategory.launcher => (
                      context.loc.launcher,
                      Icons.sports_esports,
                    ),
                    SettingsCategory.java => (context.loc.java, Icons.coffee),
                    SettingsCategory.advanced => (
                      context.loc.advanced,
                      Icons.tune,
                    ),
                    SettingsCategory.about => (context.loc.about, Icons.info),
                  };
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: PrimaryTilePane(
                      title: Text(title),
                      leading: Icon(iconData),
                      selected: state.selectedCategory == category,
                      onTap:
                          () => context
                              .read<SettingsCubit>()
                              .updateSelectedCategory(category),
                    ),
                  );
                }).toList(),
          ),
          secondaryPane: switch (state.selectedCategory) {
            SettingsCategory.general => GeneralSettingsCategory(
              generalSettings: state.settings.general,
            ),
            SettingsCategory.launcher => const Text('Launcher'),
            SettingsCategory.java => const Text('Java'),
            SettingsCategory.advanced => const Text('Advanced'),
            SettingsCategory.about => const AboutSettingsCategory(),
          },
        ),
  );
}
