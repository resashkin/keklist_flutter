import 'package:keklist/domain/repositories/tabs/models/tabs_settings.dart';

abstract class TabsContainerEvent {}

final class TabsContainerGetCurrentState extends TabsContainerEvent {}

final class TabsContainerChangeSelectedTab extends TabsContainerEvent {
  final int selectedIndex;

  TabsContainerChangeSelectedTab({required this.selectedIndex});
}

final class TabsContainerSelectTab extends TabsContainerEvent {
  final TabType tabType;

  TabsContainerSelectTab({required this.tabType});
}

final class TabsContainerUnselectTab extends TabsContainerEvent {
  final TabType tabType;

  TabsContainerUnselectTab({required this.tabType});
}

final class TabsContainerReorderTabs extends TabsContainerEvent {
  final int oldIndex;
  final int newIndex;

  TabsContainerReorderTabs({required this.oldIndex, required this.newIndex});
}
