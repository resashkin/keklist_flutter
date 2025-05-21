import 'package:keklist/domain/repositories/tabs/models/tabs_settings.dart';

final class TabsContainerState {
  final int selectedTabIndex;
  final List<TabModel> selectedTabs;
  final List<TabModel> unSelectedTabs;

  const TabsContainerState({
    required this.selectedTabIndex,
    required this.selectedTabs,
    required this.unSelectedTabs,
  });
}
