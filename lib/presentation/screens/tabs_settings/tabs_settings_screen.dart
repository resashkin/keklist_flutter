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

// Define the types of items in the list
sealed class TabsSettingsListItem {}

class SectionHeaderItem extends TabsSettingsListItem {
  final String title;
  SectionHeaderItem(this.title);
}

class DividerItem extends TabsSettingsListItem {}

class SelectedTabItem extends TabsSettingsListItem {
  final TabModel tabModel;
  SelectedTabItem(this.tabModel);
}

class UnselectedTabItem extends TabsSettingsListItem {
  final TabModel tabModel;
  UnselectedTabItem(this.tabModel);
}

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
              icon: item.type.materialIcon,
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

  List<TabsSettingsListItem> _buildListItems() {
    final List<TabsSettingsListItem> items = [];
    items.add(SectionHeaderItem('Active tabs'));
    items.addAll(_selectedTabModels.map((tab) => SelectedTabItem(tab)));
    if (_unselectedTabModels.isNotEmpty) {
      items.add(DividerItem());
      items.add(SectionHeaderItem('Unactive tabs'));
      items.addAll(_unselectedTabModels.map((tab) => UnselectedTabItem(tab)));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final listItems = _buildListItems();
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
          sendEventToBloc<TabsContainerBloc>(TabsContainerReorderTabs(
            oldIndex: oldIndex - selectedStart,
            newIndex: newIndex - selectedStart > oldIndex - selectedStart
                ? newIndex - selectedStart - 1
                : newIndex - selectedStart,
          ));
        },
        buildDefaultDragHandles: false,
        itemBuilder: (context, i) {
          final item = listItems[i];
          if (item is SectionHeaderItem) {
            return ListTile(
              key: ValueKey('header_${item.title}'),
              title: Text(item.title, style: TextStyle(fontWeight: FontWeight.bold)),
            );
          } else if (item is DividerItem) {
            return Divider(key: ValueKey('divider'), thickness: 2);
          } else if (item is SelectedTabItem) {
            final tab = item.tabModel;
            final index = _selectedTabModels.indexOf(tab);
            return KeyedSubtree(
              key: ValueKey('selected_${tab.type}'),
              child: _SelectableTabItemWidget(
                leadingIcon: tab.type.materialIcon,
                title: tab.type.label,
                subtitle: tab.type.description,
                trailingAction: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ReorderableDragStartListener(
                      index: i,
                      child: const Icon(Icons.menu),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        if (tab.type == TabType.calendar) {
                          _showCalendarRemoveErrorMessage();
                          return;
                        }
                        sendEventToBloc<TabsContainerBloc>(TabsContainerUnselectTab(tabType: tab.type));
                      },
                      child: Icon(Icons.remove),
                    ),
                  ],
                ),
                onTrailingAction: null, // handled above
              ),
            );
          } else if (item is UnselectedTabItem) {
            final tab = item.tabModel;
            return KeyedSubtree(
              key: ValueKey('unselected_${tab.type}'),
              child: _SelectableTabItemWidget(
                leadingIcon: tab.type.materialIcon,
                title: tab.type.label,
                subtitle: tab.type.description,
                trailingAction: Icon(Icons.add),
                onTrailingAction: () => sendEventToBloc<TabsContainerBloc>(TabsContainerSelectTab(tabType: tab.type)),
              ),
            );
          }
          return const SizedBox.shrink();
        },
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
    Widget trailingWidget = trailingAction ?? const SizedBox.shrink();
    // If the trailingAction is a plus icon and onTrailingAction is provided, make it tappable
    if (trailingAction is Icon && (trailingAction as Icon).icon == Icons.add && onTrailingAction != null) {
      trailingWidget = GestureDetector(
        onTap: onTrailingAction,
        child: trailingAction,
      );
    }
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
      trailing: trailingWidget,
      // trailingAction now handles its own tap logic (for drag and remove/add)
    );
  }
}
