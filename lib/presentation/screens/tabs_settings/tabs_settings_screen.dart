import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:keklist/domain/repositories/tabs/models/tabs_settings.dart';
import 'package:keklist/presentation/blocs/tabs_container_bloc/tabs_container_bloc.dart';
import 'package:keklist/presentation/blocs/tabs_container_bloc/tabs_container_event.dart';
import 'package:keklist/presentation/blocs/tabs_container_bloc/tabs_container_state.dart';
import 'package:keklist/presentation/core/helpers/bloc_utils.dart';

final class TabsSettingsScreen extends StatefulWidget {
  const TabsSettingsScreen({super.key});

  @override
  State<TabsSettingsScreen> createState() => _TabsSettingsScreenState();
}

final class _TabsSettingsScreenState extends State<TabsSettingsScreen> {
  final List<TabModel> _selectedTabModels = [];
  final List<TabModel> _unselectedTabModels = [];

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
        });
      }
    });
    sendEventToBloc<TabsContainerBloc>(TabsContainerGetCurrentState());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    (item) => _SelectableTabWidget(
                      title: item.type.label,
                      subtitle: 'Hehehehehe',
                      trailingAction: Icon(Icons.remove),
                      onTrailingAction: () =>
                          sendEventToBloc<TabsContainerBloc>(TabsContainerUnselectTab(tabType: item.type)),
                    ),
                  )
                  .toList(),
            ),
            Gap(8.0),
            Text('Unselected tabs'),
            Column(
              children: _unselectedTabModels
                  .map(
                    (item) => _SelectableTabWidget(
                      title: item.type.label,
                      subtitle: 'Hehehehehe',
                      trailingAction: Icon(Icons.remove),
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
}

final class _SelectableTabWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailingAction;
  final Function()? onTrailingAction;

  const _SelectableTabWidget({
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
      subtitle: Text(subtitle),
      trailing: GestureDetector(
        onTap: onTrailingAction,
        child: trailingAction,
      ),
    );
  }
}
