import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:kraft_launcher/common/ui/utils/build_context_ext.dart';
import 'package:kraft_launcher/common/ui/utils/home_screen_tab_ext.dart';
import 'package:kraft_launcher/settings/data/settings.dart';
import 'package:kraft_launcher/settings/ui/cubit/settings_cubit.dart';
import 'package:kraft_launcher/settings/ui/settings_section.dart';

class GeneralSettingsCategory extends StatelessWidget {
  const GeneralSettingsCategory({super.key, required this.generalSettings});

  final GeneralSettings generalSettings;

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      _AppearanceSection(generalSettings: generalSettings),
      _UiPreferencesSection(generalSettings: generalSettings),
    ],
  );
}

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection({required this.generalSettings});

  final GeneralSettings generalSettings;

  @override
  Widget build(BuildContext context) => SettingsSection(
    title: context.loc.appearance,
    tiles: [
      ListTile(
        title: Text(context.loc.appLanguage),
        subtitle: Text(context.loc.chooseYourPreferredLanguage),
        leading: const Icon(Icons.language),
        trailing: DropdownMenu(
          initialSelection: generalSettings.appLanguage,
          onSelected:
              (value) => context.read<SettingsCubit>().updateSettings(
                general: generalSettings.copyWith(appLanguage: value),
              ),
          dropdownMenuEntries:
              AppLanguage.values
                  .map(
                    (language) => DropdownMenuEntry(
                      value: language,
                      label: switch (language) {
                        AppLanguage.system => context.loc.system,
                        _ => language.labelText,
                      },
                    ),
                  )
                  .toList(),
        ),
      ),
      ListTile(
        title: Text(context.loc.themeMode),
        subtitle: Text(context.loc.selectDarkLightOrSystemTheme),
        leading: Icon(
          context.theme.brightness == Brightness.dark
              ? Icons.nightlight
              : Icons.wb_sunny_outlined,
        ),
        onTap: () {
          final newThemeMode = switch (generalSettings.themeMode) {
            ThemeMode.system => ThemeMode.light,
            ThemeMode.light => ThemeMode.dark,
            ThemeMode.dark => ThemeMode.system,
          };
          context.read<SettingsCubit>().updateSettings(
            general: generalSettings.copyWith(themeMode: newThemeMode),
          );
        },
        trailing: SegmentedButton<ThemeMode>(
          segments: <ButtonSegment<ThemeMode>>[
            ButtonSegment<ThemeMode>(
              value: ThemeMode.dark,
              icon: const Icon(Icons.nightlight_round),
              tooltip: context.loc.dark,
            ),
            ButtonSegment<ThemeMode>(
              value: ThemeMode.light,
              icon: const Icon(Icons.wb_sunny),
              tooltip: context.loc.light,
            ),
            ButtonSegment<ThemeMode>(
              value: ThemeMode.system,

              icon: const Icon(Icons.settings),
              tooltip: context.loc.system,
            ),
          ],
          selected: <ThemeMode>{generalSettings.themeMode},
          onSelectionChanged:
              (Set<ThemeMode> newSelection) =>
                  context.read<SettingsCubit>().updateSettings(
                    general: generalSettings.copyWith(
                      themeMode: newSelection.first,
                    ),
                  ),
        ),
      ),
      SwitchListTile(
        value: generalSettings.useDynamicColor,
        title: Text(context.loc.dynamicColor),
        subtitle: Text(context.loc.automaticallyAdaptToSystemColors),
        secondary: const Icon(Icons.palette),
        onChanged:
            (value) => context.read<SettingsCubit>().updateSettings(
              general: generalSettings.copyWith(useDynamicColor: value),
            ),
      ),

      ListTile(
        title: Text(context.loc.customAccentColor),
        subtitle: Text(context.loc.customizeAccentColor),
        leading: const Icon(Icons.colorize),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            ColorIndicator(
              width: 30,
              height: 30,
              borderRadius: 32,
              color: generalSettings.accentColor,
              onSelect: () async {
                final accountCubit = context.read<SettingsCubit>();

                Color? pickedColor;

                await showDialog<void>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: Text(context.loc.pickAColor),
                        content: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: 400,
                            maxWidth: 400,
                          ),
                          child: SingleChildScrollView(
                            child: ColorPicker(
                              color: generalSettings.accentColor,
                              onColorChanged: (color) => pickedColor = color,
                              pickersEnabled: const {
                                ColorPickerType.wheel: true,
                              },
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(context.loc.close),
                          ),
                        ],
                      ),
                );
                if (pickedColor != null) {
                  accountCubit.updateSettings(
                    general: generalSettings.copyWith(accentColor: pickedColor),
                  );
                }
              },
            ),
            Switch(
              value: generalSettings.useAccentColor,
              onChanged:
                  generalSettings.useDynamicColor
                      ? null
                      : (value) => context.read<SettingsCubit>().updateSettings(
                        general: generalSettings.copyWith(
                          useAccentColor: value,
                        ),
                      ),
            ),
          ],
        ),
      ),
      SwitchListTile(
        value: generalSettings.useClassicMaterialDesign,
        title: Text(context.loc.classicMaterialDesign),
        subtitle: Text(context.loc.useClassicMaterialDesignTheme),
        secondary: const Icon(Icons.android),
        onChanged:
            (value) => context.read<SettingsCubit>().updateSettings(
              general: generalSettings.copyWith(
                useClassicMaterialDesign: value,
              ),
            ),
      ),
    ],
  );
}

class _UiPreferencesSection extends StatelessWidget {
  const _UiPreferencesSection({required this.generalSettings});

  final GeneralSettings generalSettings;

  @override
  Widget build(BuildContext context) => SettingsSection(
    title: context.loc.uiPreferences,
    tiles: [
      ListTile(
        title: Text(context.loc.defaultTab),
        subtitle: Text(context.loc.initialTabSelectionDescription),
        leading: const Icon(Icons.tab),
        trailing: DropdownMenu(
          // Rebuild to use correct localization label for the selected item
          key: ValueKey(Localizations.localeOf(context)),
          initialSelection: generalSettings.defaultTab,
          onSelected:
              (value) => context.read<SettingsCubit>().updateSettings(
                general: generalSettings.copyWith(defaultTab: value),
              ),
          dropdownMenuEntries:
              HomeScreenTab.values
                  .map(
                    (tab) => DropdownMenuEntry(
                      value: tab,
                      label: tab.getLabel(context.loc),
                      leadingIcon: Icon(tab.selectedIconData),
                    ),
                  )
                  .toList(),
        ),
      ),
    ],
  );
}
