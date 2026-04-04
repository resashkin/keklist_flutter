import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:keklist/domain/repositories/debug_menu/debug_menu_repository.dart';
import 'package:keklist/presentation/blocs/debug_menu_bloc/debug_menu_bloc.dart';
import 'package:keklist/presentation/blocs/lazy_onboarding_bloc/lazy_onboarding_bloc.dart';
import 'package:keklist/presentation/blocs/membership_bloc/membership_bloc.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';
import 'package:keklist/presentation/core/helpers/bloc_utils.dart';
import 'package:keklist/presentation/core/screen/kek_screen_state.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';
import 'package:settings_ui/settings_ui.dart';

final class DebugMenuScreen extends StatefulWidget {
  const DebugMenuScreen({super.key});

  @override
  State<DebugMenuScreen> createState() => _DebugMenuScreenState();
}

final class _DebugMenuScreenState extends KekWidgetState<DebugMenuScreen> {
  List<DebugMenuData> _debugMenuItems = [];

  @override
  void initState() {
    super.initState();

    subscribeToBloc<DebugMenuBloc>(onNewState: (state) {
      if (state is DebugMenuDataState) {
        setState(() {
          _debugMenuItems = state.debugMenuItems;
        });
      }
    })?.disposed(by: this);
    sendEventToBloc<DebugMenuBloc>(DebugMenuGet());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.debugMenu)),
      body: SettingsList(
        sections: [
          if (_debugMenuItems.isNotEmpty)
            SettingsSection(
              title: const Text('Feature Flags'),
              tiles: _debugMenuItems.map((debugMenuItem) {
                return SettingsTile.switchTile(
                  title: Text(_getDebugMenuItemTitle(debugMenuItem.type)),
                  description: Text(_getDebugMenuItemDescription(debugMenuItem.type)),
                  onToggle: (bool value) {
                    if (debugMenuItem.type == DebugMenuType.simulatePro && value == true) {
                      _onEnableSimulatePro();
                    } else {
                      sendEventToBloc<DebugMenuBloc>(
                        DebugMenuUpdate(
                          flagType: debugMenuItem.type,
                          value: value,
                        ),
                      );
                      if (debugMenuItem.type == DebugMenuType.simulatePro) {
                        sendEventToBloc<MembershipBloc>(const MembershipRefreshEvent());
                      }
                    }
                  },
                  initialValue: debugMenuItem.value,
                );
              }).toList(),
            ),
          SettingsSection(
            title: const Text('Development Tools'),
            tiles: [
              SettingsTile.navigation(
                title: const Text('Reset Lazy Onboarding'),
                description: const Text('Delete onboarding minds and reset the flag to show onboarding again'),
                onPressed: (context) => _resetOnboarding(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onEnableSimulatePro() async {
    final TextEditingController controller = TextEditingController();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Developer Password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter password'),
          onSubmitted: (_) => Navigator.of(context).pop(true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    final String? devPassword = dotenv.env['DEVELOPER_PRO_PASSWORD'];
    if (confirmed == true && controller.text == devPassword) {
      sendEventToBloc<DebugMenuBloc>(
        const DebugMenuUpdate(flagType: DebugMenuType.simulatePro, value: true),
      );
      sendEventToBloc<MembershipBloc>(const MembershipRefreshEvent());
    } else if (confirmed == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect password'), duration: Duration(seconds: 2)),
        );
      }
    }
  }

  void _resetOnboarding(BuildContext context) {
    sendEventToBloc<LazyOnboardingBloc>(LazyOnboardingReset());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lazy onboarding has been reset'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _getDebugMenuItemTitle(DebugMenuType type) => switch (type) {
        DebugMenuType.translation => 'Translate Content',
        DebugMenuType.sensitiveContent => 'Sensitive Content',
        DebugMenuType.simulatePro => 'Simulate Pro Subscription',
      };

  String _getDebugMenuItemDescription(DebugMenuType type) => switch (type) {
        DebugMenuType.translation =>
          'Showing/Hiding Translate action, that just opens Alert with translation on English.',
        DebugMenuType.sensitiveContent =>
          'Showing/Hiding Eye button that allows to hide content for users when you showing phone to others.',
        DebugMenuType.simulatePro =>
          'Forces isPro=true in MembershipBloc, bypassing RevenueCat. Password required to enable.',
      };
}
