import 'package:flutter/material.dart';
import 'package:keklist/domain/repositories/tabs/models/tabs_settings.dart';
import 'package:keklist/presentation/blocs/tabs_container_bloc/tabs_container_bloc.dart';
import 'package:keklist/presentation/blocs/tabs_container_bloc/tabs_container_event.dart';
import 'package:keklist/presentation/blocs/tabs_container_bloc/tabs_container_state.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';
import 'package:keklist/presentation/core/helpers/bloc_utils.dart';
import 'package:keklist/presentation/core/widgets/bool_widget.dart';
import 'package:keklist/presentation/screens/mind_collection/mind_collection_screen.dart';

final class TabsContainerScreen extends StatefulWidget {
  const TabsContainerScreen({super.key});

  @override
  State<TabsContainerScreen> createState() => _TabsContainerScreenState();
}

final class _TabsContainerScreenState extends State<TabsContainerScreen> with DisposeBag {
  int _selectedTabIndex = 0;
  final List<BottomNavigationBarItem> _items = [];

  @override
  void initState() {
    super.initState();

    subscribeToBloc<TabsContainerBloc>(onNewState: (state) async {
      if (state is TabsContainerState) {
        setState(() {
          _selectedTabIndex = state.selectedTabIndex;
          _items.clear();
          final Iterable<BottomNavigationBarItem> items = state.tabs.map(
            (item) => BottomNavigationBarItem(
              icon: _getTabIcon(item.type),
              label: item.type.label,
            ),
          );
          _items.addAll(items);
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
      bottomNavigationBar: BoolWidget(
        condition: _items.isNotEmpty,
        trueChild: BottomNavigationBar(
          enableFeedback: true,
          items: _items.isEmpty
              ? [
                  BottomNavigationBarItem(icon: SizedBox(), label: ''),
                  BottomNavigationBarItem(icon: SizedBox(), label: ''),
                ]
              : _items,
          currentIndex: _selectedTabIndex,
          onTap: (tabIndex) =>
              sendEventToBloc<TabsContainerBloc>(TabsContainerChangeSelectedTab(selectedIndex: tabIndex)),
          useLegacyColorScheme: false,
        ),
        falseChild: SizedBox.shrink(),
      ),
      body: MindCollectionScreen(),
    );
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
