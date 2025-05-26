import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:keklist/domain/repositories/tabs/models/tabs_settings.dart';
import 'package:keklist/presentation/blocs/tabs_container_bloc/tabs_container_bloc.dart';
import 'package:keklist/presentation/blocs/tabs_container_bloc/tabs_container_event.dart';
import 'package:keklist/presentation/blocs/tabs_container_bloc/tabs_container_state.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';
import 'package:keklist/presentation/core/helpers/bloc_utils.dart';
import 'package:keklist/presentation/core/widgets/bool_widget.dart';
import 'package:keklist/presentation/core/widgets/bottom_navigation_bar.dart';

final class TabsSettingsScreen extends StatefulWidget {
  const TabsSettingsScreen({super.key});

  @override
  State<TabsSettingsScreen> createState() => _TabsSettingsScreenState();
}

final class _TabsSettingsScreenState extends State<TabsSettingsScreen> with DisposeBag {
  int _selectedIndex = 0;
  final List<TabModel> _selectedTabModels = [];
  final List<TabModel> _unselectedTabModels = [];
  final List<BottomNavigationBarItem> _items = [];

  @override
  void initState() {
    super.initState();

    subscribeToBloc<TabsContainerBloc>(onNewState: (state) {
      if (state is TabsContainerState) {
        setState(() {
          _selectedIndex = 0;
          _selectedTabModels
            ..clear()
            ..addAll(state.selectedTabs);
          _unselectedTabModels
            ..clear()
            ..addAll(state.unSelectedTabs);
          final Iterable<BottomNavigationBarItem> items = state.selectedTabs.map(
            (item) => BottomNavigationBarItem(
              icon: _getTabIcon(item.type),
              label: item.type.label,
            ),
          );
          _items
            ..clear()
            ..addAll(items);
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

  List<BottomNavigationBarItem> get _getTwoFakeItems => [
        BottomNavigationBarItem(
          icon: TabType.calendar.materialIcon,
          label: TabType.calendar.label,
        ),
        BottomNavigationBarItem(
          icon: TabType.settings.materialIcon,
          label: TabType.settings.label,
        )
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BoolWidget(
        condition: _items.length >= 2,
        falseChild: const SizedBox.shrink(),
        trueChild: AdaptiveBottomNavigationBar(
          items: List.of(_items.length >= 2 ? _items : _getTwoFakeItems),
          selectedIndex: _selectedIndex,
          onTap: (int index) => setState(() => _selectedIndex = index),
        ),
      ),
      appBar: AppBar(
        title: Text('Tabs settings'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Gap(8.0),
            Text('Selected tabs'),
            Column(
              children: _selectedTabModels
                  .map(
                    (item) => _SelectableTabItemWidget(
                      leadingIcon: item.type.materialIcon,
                      title: item.type.label,
                      subtitle: item.type.description,
                      trailingAction: Icon(Icons.remove),
                      onTrailingAction: () {
                        if (item.type == TabType.calendar) {
                          _showCalendarRemoveErrorMessage();
                          return;
                        }
                        sendEventToBloc<TabsContainerBloc>(TabsContainerUnselectTab(tabType: item.type));
                      },
                    ),
                  )
                  .toList(),
            ),
            Gap(8.0),
            if (_unselectedTabModels.isNotEmpty) Divider(),
            if (_unselectedTabModels.isNotEmpty) Text('Unselected tabs'),
            if (_unselectedTabModels.isNotEmpty)
              Column(
                children: _unselectedTabModels
                    .map(
                      (item) => _SelectableTabItemWidget(
                        leadingIcon: item.type.materialIcon,
                        title: item.type.label,
                        subtitle: item.type.description,
                        trailingAction: Icon(Icons.add),
                        onTrailingAction: () =>
                            sendEventToBloc<TabsContainerBloc>(TabsContainerSelectTab(tabType: item.type)),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  void _showCalendarRemoveErrorMessage() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Cannot remove main screen. You will loose option to setup tabs.'),
        ),
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

final class _SelectableTabItemWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final Icon leadingIcon;
  final Widget? trailingAction;
  final Function()? onTrailingAction;

  const _SelectableTabItemWidget({
    required this.title,
    required this.subtitle,
    required this.trailingAction,
    required this.onTrailingAction,
    required this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blueGrey,
        child: leadingIcon,
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.blueGrey),
      ),
      trailing: GestureDetector(
        onTap: onTrailingAction,
        child: trailingAction,
      ),
    );
  }
}
