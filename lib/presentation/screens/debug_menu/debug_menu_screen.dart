import 'package:flutter/material.dart';
import 'package:keklist/domain/repositories/debug_menu/debug_menu_repository.dart';
import 'package:keklist/presentation/blocs/debug_menu_bloc/debug_menu_bloc.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';
import 'package:keklist/presentation/core/helpers/bloc_utils.dart';
import 'package:keklist/presentation/core/screen/kek_screen_state.dart';
import 'package:keklist/presentation/core/widgets/bool_widget.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Menu')),
      body: BoolWidget(
        condition: _debugMenuItems.isNotEmpty,
        trueChild: SettingsList(
          sections: [
            SettingsSection(
              tiles: _debugMenuItems.map((debugMenuItem) {
                return SettingsTile.switchTile(
                  title: Text(_getDebugMenuItemTitle(debugMenuItem.type)),
                  description: Text(_getDebugMenuItemDescription(debugMenuItem.type)),
                  onToggle: (bool value) {
                    sendEventToBloc<DebugMenuBloc>(
                      DebugMenuUpdate(
                        flagType: debugMenuItem.type,
                        value: value,
                      ),
                    );
                  },
                  initialValue: debugMenuItem.value,
                );
              }).toList(),
            ),
          ],
        ),
        falseChild: SizedBox.shrink(),
      ),
    );
  }

  String _getDebugMenuItemTitle(DebugMenuType type) => switch (type) {
        DebugMenuType.chatWithAI => 'Chat with AI',
        DebugMenuType.translation => 'Translate content',
        DebugMenuType.sensitiveContent => 'Sensitive content',
      };

  String _getDebugMenuItemDescription(DebugMenuType type) => switch (type) {
        DebugMenuType.chatWithAI => 'Showing/Hiding Chat with AI action, that allows to discuss Mind with AI in chat.',
        DebugMenuType.translation =>
          'Showing/Hiding Translate action, that just opens Alert with translation on English.',
        DebugMenuType.sensitiveContent =>
          'Showing/Hiding Eye button that allows to hide content for users when you showing phone to others.',
      };
}
