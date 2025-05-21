import 'dart:math';

import 'package:flutter/material.dart';
import 'package:keklist/domain/repositories/tabs/models/tabs_settings.dart';
import 'package:keklist/presentation/blocs/tabs_container_bloc/tabs_container_bloc.dart';
import 'package:keklist/presentation/blocs/tabs_container_bloc/tabs_container_event.dart';
import 'package:keklist/presentation/blocs/tabs_container_bloc/tabs_container_state.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';
import 'package:keklist/presentation/core/helpers/bloc_utils.dart';
import 'package:keklist/presentation/screens/insights/insights_screen.dart';
import 'package:keklist/presentation/screens/mind_collection/mind_collection_screen.dart';
import 'package:keklist/presentation/screens/settings/settings_screen.dart';
import 'package:keklist/presentation/screens/user_profile/user_profile_screen.dart';

final class TabsContainerScreen extends StatefulWidget {
  const TabsContainerScreen({super.key});

  @override
  State<TabsContainerScreen> createState() => _TabsContainerScreenState();
}

final class _TabsContainerScreenState extends State<TabsContainerScreen> with DisposeBag {
  int _selectedTabIndex = 0;
  final List<BottomNavigationBarItem> _items = [];
  final List<Widget> _bodyWidgets = [MindCollectionScreen()];

  @override
  void initState() {
    super.initState();

    subscribeToBloc<TabsContainerBloc>(onNewState: (state) async {
      if (state is TabsContainerState) {
        setState(() {
          _selectedTabIndex = state.selectedTabIndex;
          final Iterable<BottomNavigationBarItem> items = state.selectedTabs.map(
            (item) => BottomNavigationBarItem(
              icon: _getTabIcon(item.type),
              label: item.type.label,
            ),
          );
          _items
            ..clear()
            ..addAll(items);

          final Iterable<Widget> bodyWidgets = state.selectedTabs.map((item) => item.type).map(_bodyWidgetByType);
          _bodyWidgets
            ..clear()
            ..addAll(bodyWidgets);
        });
      }
    })?.disposed(by: this);
    sendEventToBloc<TabsContainerBloc>(TabsContainerGetCurrentState());
  }

  @override
  void dispose() {
    super.dispose();

    cancelSubscriptions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        enableFeedback: true,
        items: _items.length >= 2
            ? _items
            : [
                BottomNavigationBarItem(icon: _getTabIcon(TabType.calendar), label: '1'),
                BottomNavigationBarItem(icon: _getTabIcon(TabType.settings), label: '2'),
                BottomNavigationBarItem(icon: _getTabIcon(TabType.profile), label: '3'),
              ],
        currentIndex: max(_selectedTabIndex, 0),
        onTap: (tabIndex) =>
            sendEventToBloc<TabsContainerBloc>(TabsContainerChangeSelectedTab(selectedIndex: tabIndex)),
        useLegacyColorScheme: false,
      ),
      body: IndexedStack(
        index: _selectedTabIndex,
        children: _bodyWidgets,
      ),
    );
  }

  Widget _bodyWidgetByType(TabType type) {
    switch (type) {
      case TabType.calendar:
        return MindCollectionScreen();
      case TabType.insights:
        return InsightsScreen();
      case TabType.profile:
        return UserProfileScreen();
      case TabType.settings:
        return SettingsScreen();
    }
  }

  Icon _getTabIcon(TabType type) {
    switch (type) {
      case TabType.calendar:
        return Icon(Icons.calendar_month);
      case TabType.insights:
        return Icon(Icons.insights);
      case TabType.profile:
        return Icon(Icons.person);
      case TabType.settings:
        return Icon(Icons.settings);
    }
  }
}
