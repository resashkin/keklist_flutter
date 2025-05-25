import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:keklist/domain/repositories/tabs/models/tabs_settings.dart';
import 'package:keklist/presentation/blocs/tabs_container_bloc/tabs_container_bloc.dart';
import 'package:keklist/presentation/blocs/tabs_container_bloc/tabs_container_event.dart';
import 'package:keklist/presentation/blocs/tabs_container_bloc/tabs_container_state.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';
import 'package:keklist/presentation/core/helpers/bloc_utils.dart';
import 'package:keklist/presentation/core/widgets/bool_widget.dart';

final class TabsSettingsScreen extends StatefulWidget {
  const TabsSettingsScreen({super.key});

  @override
  State<TabsSettingsScreen> createState() => _TabsSettingsScreenState();
}

final class _TabsSettingsScreenState extends State<TabsSettingsScreen> with DisposeBag {
  final List<TabModel> _selectedTabModels = [];
  final List<TabModel> _unselectedTabModels = [];
  final List<BottomNavigationBarItem> _items = [];

  @override
  void initState() {
    super.initState();

    subscribeToBloc<TabsContainerBloc>(onNewState: (state) {
      if (state is TabsContainerState) {
        setState(() {
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

  List<BottomNavigationBarItem> get _getFakeItems => [
        BottomNavigationBarItem(icon: _getTabIcon(TabType.calendar), label: 'fake_1'),
        BottomNavigationBarItem(icon: _getTabIcon(TabType.settings), label: 'fake_2')
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BoolWidget(
        condition: _items.length >= 2,
        falseChild: const SizedBox.shrink(),
        trueChild: BottomNavigationBar(
          enableFeedback: true,
          items: List.of(_items.length >= 2 ? _items : _getFakeItems),
          currentIndex: 0,
          useLegacyColorScheme: false,
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Cannot remove main screen. You will loose availibility to setup your data.'),
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
  final Widget? trailingAction;
  final Function()? onTrailingAction;

  const _SelectableTabItemWidget({
    required this.title,
    required this.subtitle,
    required this.trailingAction,
    required this.onTrailingAction,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xff764abc),
        child: Text(title),
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
