import 'package:flutter/material.dart';
import 'package:keklist/presentation/blocs/tab_container_bloc/tab_container_bloc.dart';
import 'package:keklist/presentation/blocs/tab_container_bloc/tab_container_event.dart';
import 'package:keklist/presentation/blocs/tab_container_bloc/tab_container_state.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';
import 'package:keklist/presentation/core/helpers/bloc_utils.dart';
import 'package:keklist/presentation/core/widgets/bool_widget.dart';
import 'package:keklist/presentation/screens/mind_collection/mind_collection_screen.dart';

final class TabContainerScreen extends StatefulWidget {
  const TabContainerScreen({super.key});

  @override
  State<TabContainerScreen> createState() => _TabContainerScreenState();
}

final class _TabContainerScreenState extends State<TabContainerScreen> with DisposeBag {
  int _selectedTabIndex = 0;
  final List<BottomNavigationBarItem> _items = [];

  @override
  void initState() {
    super.initState();

    subscribeTo<TabContainerBloc>(onNewState: (state) async {
      if (state is TabContainerState) {
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
    sendEventTo<TabContainerBloc>(TabContainerGetCurrentState());
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
          onTap: (tabIndex) => sendEventTo<TabContainerBloc>(TabContainerChangeSelectedTab(selectedIndex: tabIndex)),
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
