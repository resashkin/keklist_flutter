import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keklist/domain/repositories/debug_menu/debug_menu_repository.dart';
import 'package:keklist/domain/repositories/tabs/models/tabs_settings.dart';
import 'package:keklist/presentation/blocs/debug_menu_bloc/debug_menu_bloc.dart';
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
  bool _useLiquidGlass = false;
  final GlobalKey<MindDayCollectionScreenState> _todayKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    subscribeToBloc<TabsContainerBloc>(
      onNewState: (state) async {
        if (state is TabsContainerState) {
          setState(() {
            _selectedTabIndex = state.selectedTabIndex;
            final Iterable<BottomNavigationBarItem> items = state.selectedTabs.map(
              (item) => BottomNavigationBarItem(icon: item.type.materialIcon, label: item.type.localizedLabel(context)),
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
      },
    )?.disposed(by: this);
    sendEventToBloc<TabsContainerBloc>(TabsContainerGetCurrentState());

    _useLiquidGlass = _readUseLiquidGlass(context.read<DebugMenuBloc>().state);
    subscribeToBloc<DebugMenuBloc>(
      onNewState: (state) {
        final bool next = _readUseLiquidGlass(state);
        if (next != _useLiquidGlass) {
          setState(() {
            _useLiquidGlass = next;
            // Rebuild the cached body children so screens that depend on the
            // theme (e.g. the Today tab's `fabBottomOffset`) pick up the new
            // value instead of keeping their build-time offset.
            final Iterable<Widget> bodyWidgets = _tabTypes.map(_bodyWidgetByType);
            _bodyWidgets
              ..clear()
              ..addAll(bodyWidgets);
          });
        }
      },
    )?.disposed(by: this);
  }

  bool _readUseLiquidGlass(DebugMenuState state) {
    if (state is! DebugMenuDataState) return _useLiquidGlass;
    return state.debugMenuItems
        .firstWhere(
          (item) => item.type == DebugMenuType.uiTheme,
          orElse: () => DebugMenuData(type: DebugMenuType.uiTheme, value: true),
        )
        .value;
  }

  @override
  void dispose() {
    super.dispose();

    cancelSubscriptions();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBody: _useLiquidGlass,
    body: IndexedStack(index: _selectedTabIndex, children: _bodyWidgets),
    bottomNavigationBar: BoolWidget(
      condition: _items.length >= 2,
      trueChild: AdaptiveBottomNavigationBar(
        items: List.of(_items.length >= 2 ? _items : _getFakeItems()),
        tabTypes: _tabTypes,
        useLiquidGlass: _useLiquidGlass,
        selectedIndex: _selectedTabIndex,
        onTap: (tabIndex) {
          if (tabIndex == _selectedTabIndex && tabIndex < _tabTypes.length && _tabTypes[tabIndex] == TabType.today) {
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
    BottomNavigationBarItem(icon: TabType.calendar.materialIcon, label: TabType.calendar.localizedLabel(context)),
    BottomNavigationBarItem(icon: TabType.settings.materialIcon, label: TabType.settings.localizedLabel(context)),
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
        return MindDayCollectionScreen(
          key: _todayKey,
          initialDayIndex: DateUtils.getTodayIndex(),
          // Only lift the FAB above the translucent Liquid Glass nav bar, which
          // overlaps the body via `extendBody`. In Material mode the solid nav
          // bar already reserves its space, so the extra offset would leave a
          // strange gap under the FAB.
          fabBottomOffset: _useLiquidGlass ? kBottomNavigationBarHeight + 48.0 : 0.0,
        );
      case TabType.debugMenu:
        return const SizedBox.shrink();
    }
  }
}
