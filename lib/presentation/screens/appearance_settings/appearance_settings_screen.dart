import 'package:flutter/material.dart';
import 'package:keklist/domain/repositories/settings/keklist_interface_style.dart';
import 'package:keklist/domain/repositories/settings/keklist_theme_mode.dart';
import 'package:keklist/presentation/blocs/settings_bloc/settings_bloc.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';
import 'package:keklist/presentation/core/helpers/bloc_utils.dart';
import 'package:keklist/presentation/core/helpers/interface_style_utils.dart';
import 'package:keklist/presentation/core/screen/kek_screen_state.dart';
import 'package:keklist/presentation/core/widgets/settings/settings_section.dart';

final class AppearanceSettingsScreen extends StatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  State<AppearanceSettingsScreen> createState() => _AppearanceSettingsScreenState();
}

final class _AppearanceSettingsScreenState extends KekWidgetState<AppearanceSettingsScreen> {
  KeklistThemeMode _themePreference = KeklistThemeMode.system;
  KeklistInterfaceStyle _interfaceStyle = KeklistInterfaceStyle.liquidGlass;

  @override
  void initState() {
    super.initState();

    subscribeToBloc<SettingsBloc>(
      onNewState: (state) {
        if (state is SettingsDataState) {
          setState(() {
            _themePreference = state.settings.themePreference;
            _interfaceStyle = state.settings.interfaceStyle;
          });
        }
      },
    )?.disposed(by: this);
    sendEventToBloc<SettingsBloc>(SettingsGet());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.appearance)),
      body: SettingsListView(
        children: [
          SettingsSectionHeader(context.l10n.appearance.toUpperCase()),
          SettingsSectionCard(
            children: [
              if (isLiquidGlassAvailableOnThisPlatform())
                SettingsMenuTile<KeklistInterfaceStyle>(
                  leading: const Icon(Icons.blur_on, color: Colors.grey),
                  title: context.l10n.interfaceStyle,
                  value: _interfaceStyle,
                  options: const [
                    SettingsMenuOption(value: KeklistInterfaceStyle.material, label: 'Material'),
                    SettingsMenuOption(value: KeklistInterfaceStyle.liquidGlass, label: 'Liquid Glass'),
                  ],
                  onSelected: (value) =>
                      sendEventToBloc<SettingsBloc>(SettingsChangeInterfaceStyle(interfaceStyle: value)),
                ),
              SettingsMenuTile<KeklistThemeMode>(
                leading: const Icon(Icons.brightness_medium, color: Colors.grey),
                title: context.l10n.theme,
                value: _themePreference,
                options: [
                  SettingsMenuOption(value: KeklistThemeMode.light, label: context.l10n.themeLight),
                  SettingsMenuOption(value: KeklistThemeMode.dark, label: context.l10n.themeDark),
                  SettingsMenuOption(value: KeklistThemeMode.system, label: context.l10n.themeSystem),
                ],
                onSelected: (value) =>
                    sendEventToBloc<SettingsBloc>(SettingsChangeThemePreference(themePreference: value)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
