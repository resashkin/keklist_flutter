import 'package:flutter/material.dart' hide DateUtils;
import 'package:keklist/domain/repositories/tabs/models/tabs_settings.dart';
import 'package:keklist/presentation/blocs/tabs_container_bloc/tabs_container_bloc.dart';
import 'package:keklist/presentation/blocs/tabs_container_bloc/tabs_container_event.dart';
import 'package:keklist/presentation/blocs/tabs_container_bloc/tabs_container_state.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';
import 'package:keklist/presentation/core/helpers/bloc_utils.dart';
import 'package:keklist/presentation/core/helpers/date_utils.dart';
import 'package:keklist/presentation/core/widgets/bool_widget.dart';
import 'package:keklist/presentation/core/widgets/bottom_navigation_bar.dart';
import 'package:keklist/presentation/screens/insights/insights_screen.dart';
import 'package:keklist/presentation/screens/mind_collection/mind_collection_screen.dart';
import 'package:keklist/presentation/screens/mind_day_collection/mind_day_collection_screen.dart';
import 'package:keklist/presentation/screens/settings/settings_screen.dart';
import 'package:keklist/presentation/screens/user_profile/user_profile_screen.dart';
import 'package:keklist/presentation/screens/debug_menu/debug_menu_screen.dart';

final class TabsContainerScreen extends StatefulWidget {
  const TabsContainerScreen({super.key});

  @override
  State<TabsContainerScreen> createState() => _TabsContainerScreenState();
}

final class _TabsContainerScreenState extends State<TabsContainerScreen> with DisposeBag {
  int _selectedTabIndex = 0;
  final List<BottomNavigationBarItem> _items = [];
  final List<Widget> _bodyWidgets = [];
  List<TabType> _tabTypes = [];
  final GlobalKey<MindDayCollectionScreenState> _todayKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    subscribeToBloc<TabsContainerBloc>(onNewState: (state) async {
      if (state is TabsContainerState) {
        setState(() {
          _selectedTabIndex = state.selectedTabIndex;
          final Iterable<BottomNavigationBarItem> items = state.selectedTabs.map(
            (item) => BottomNavigationBarItem(
              icon: item.type.materialIcon,
              label: item.type.localizedLabel(context),
            ),
          );
          _items
            ..clear()
            ..addAll(items);

          _tabTypes = state.selectedTabs.map((item) => item.type).toList();
          final Iterable<Widget> bodyWidgets = _tabTypes.map(_bodyWidgetByType);
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
  Widget build(BuildContext context) => Scaffold(
        body: BoolWidget(
          condition: _bodyWidgets.isNotEmpty,
          trueChild: IndexedStack(
            index: _selectedTabIndex,
            children: _bodyWidgets,
          ),
          falseChild: MindCollectionScreen(),
        ),
        bottomNavigationBar: BoolWidget(
          condition: _items.length >= 2,
          trueChild: AdaptiveBottomNavigationBar(
            items: List.of(_items.length >= 2 ? _items : _getFakeItems()),
            selectedIndex: _selectedTabIndex,
            onTap: (tabIndex) {
              if (tabIndex == _selectedTabIndex &&
                  tabIndex < _tabTypes.length &&
                  _tabTypes[tabIndex] == TabType.today) {
                _todayKey.currentState?.goToToday();
              } else {
                sendEventToBloc<TabsContainerBloc>(TabsContainerChangeSelectedTab(selectedIndex: tabIndex));
              }
            },
          ),
          falseChild: SizedBox.shrink(),
        ),
      );

  List<BottomNavigationBarItem> _getFakeItems() => [
        BottomNavigationBarItem(
          icon: TabType.calendar.materialIcon,
          label: TabType.calendar.localizedLabel(context),
        ),
        BottomNavigationBarItem(
          icon: TabType.settings.materialIcon,
          label: TabType.settings.localizedLabel(context),
        )
      ];

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
      case TabType.today:
        return MindDayCollectionScreen(key: _todayKey, initialDayIndex: DateUtils.getTodayIndex());
      case TabType.debugMenu:
        return DebugMenuScreen();
    }
  }
}
