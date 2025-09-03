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
import 'package:keklist/presentation/screens/tabs_settings/tabs_settings_list_item.dart';

final class TabsSettingsScreen extends StatefulWidget {
  const TabsSettingsScreen({super.key});

  @override
  State<TabsSettingsScreen> createState() => _TabsSettingsScreenState();
}

final class _TabsSettingsScreenState extends State<TabsSettingsScreen> with DisposeBag {
  int _selectedIndex = 0;
  final List<TabModel> _selectedTabModels = [];
  final List<TabModel> _hiddenTabModels = [];
  final List<BottomNavigationBarItem> _tabItems = [];

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
          _hiddenTabModels
            ..clear()
            ..addAll(state.hiddenTabs);
          final Iterable<BottomNavigationBarItem> items = state.selectedTabs.map(
            (item) => BottomNavigationBarItem(
              icon: item.type.materialIcon,
              label: item.type.label,
            ),
          );
          _tabItems
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

  @override
  Widget build(BuildContext context) {
    final listItems = _buildListItems();
    return Scaffold(
      bottomNavigationBar: BoolWidget(
        condition: _tabItems.length >= 2,
        falseChild: const SizedBox.shrink(),
        trueChild: AdaptiveBottomNavigationBar(
          items: List.of(_tabItems.length >= 2 ? _tabItems : _buildFakeItems()),
          selectedIndex: _selectedIndex,
          onTap: (int index) => setState(() => _selectedIndex = index),
        ),
      ),
      appBar: AppBar(title: Text('Tabs settings')),
      body: ReorderableListView.builder(
        itemCount: listItems.length,
        onReorder: (oldIndex, newIndex) {
          // Only allow reordering of selected tabs
          final selectedStart = 1;
          final selectedEnd = selectedStart + _selectedTabModels.length;
          if (oldIndex < selectedStart ||
              oldIndex >= selectedEnd ||
              newIndex < selectedStart ||
              newIndex > selectedEnd) {
            return;
          }
          setState(() {
            final item = _selectedTabModels.removeAt(oldIndex - selectedStart);
            _selectedTabModels.insert(
                newIndex - selectedStart > oldIndex - selectedStart
                    ? newIndex - selectedStart - 1
                    : newIndex - selectedStart,
                item);
          });
          sendEventToBloc<TabsContainerBloc>(
            TabsContainerReorderTabs(
              oldIndex: oldIndex - selectedStart,
              newIndex: newIndex - selectedStart > oldIndex - selectedStart
                  ? newIndex - selectedStart - 1
                  : newIndex - selectedStart,
            ),
          );
        },
        buildDefaultDragHandles: false,
        itemBuilder: (context, index) {
          final item = listItems[index];
          switch (item) {
            case SectionHeaderItem():
              return ListTile(
                key: ValueKey('header_${item.title}'),
                title: Text(item.title, style: TextStyle(fontWeight: FontWeight.bold)),
              );
            case DividerItem():
              return Divider(key: ValueKey('divider'), thickness: 2);
            case SelectedTabItem():
              final tab = item.tabModel;
              return KeyedSubtree(
                key: ValueKey('selected_${tab.type}'),
                child: _TabItemWidget(
                  leadingIcon: tab.type.materialIcon,
                  title: tab.type.label,
                  subtitle: tab.type.description,
                  trailingActionWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.menu),
                      ),
                      const Gap(8.0),
                      GestureDetector(
                        onTap: () => handleRemoveItem(tabType: tab.type),
                        child: Icon(Icons.remove),
                      ),
                    ],
                  ),
                ),
              );
            case HiddenTabItem():
              final tab = item.tabModel;
              return KeyedSubtree(
                key: ValueKey('unselected_${tab.type}'),
                child: _TabItemWidget(
                  leadingIcon: tab.type.materialIcon,
                  title: tab.type.label,
                  subtitle: tab.type.description,
                  trailingActionWidget: GestureDetector(
                    child: Icon(Icons.add),
                    onTap: () => sendEventToBloc<TabsContainerBloc>(TabsContainerSelectTab(tabType: tab.type)),
                  ),
                ),
              );
          }
        },
      ),
    );
  }

  void handleRemoveItem({required TabType tabType}) {
    if (tabType == TabType.calendar) {
      _showCalendarRemoveErrorMessage();
      return;
    }
    sendEventToBloc<TabsContainerBloc>(TabsContainerUnselectTab(tabType: tabType));
  }

  List<BottomNavigationBarItem> _buildFakeItems() => [
        BottomNavigationBarItem(
          icon: TabType.calendar.materialIcon,
          label: TabType.calendar.label,
        ),
        BottomNavigationBarItem(
          icon: TabType.settings.materialIcon,
          label: TabType.settings.label,
        )
      ];

  List<TabsSettingsListItem> _buildListItems() {
    final List<TabsSettingsListItem> items = [];
    items.add(SectionHeaderItem('Active tabs'));
    items.addAll(_selectedTabModels.map((tab) => SelectedTabItem(tab)));
    if (_hiddenTabModels.isNotEmpty) {
      items.add(DividerItem());
      items.add(SectionHeaderItem('Hidden tabs'));
      items.addAll(_hiddenTabModels.map((tab) => HiddenTabItem(tab)));
    }
    return items;
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
}

final class _TabItemWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final Icon leadingIcon;
  final Widget? trailingActionWidget;

  const _TabItemWidget({
    required this.title,
    required this.subtitle,
    required this.trailingActionWidget,
    required this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueGrey,
          child: leadingIcon,
        ),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.blueGrey),
        ),
        trailing: trailingActionWidget,
      );
}
