import 'package:keklist/domain/repositories/tabs/models/tabs_settings.dart';

final class TabsContainerState {
  final int selectedTabIndex;
  final List<TabModel> tabs;

  const TabsContainerState({
    required this.selectedTabIndex,
    required this.tabs,
  });
}
