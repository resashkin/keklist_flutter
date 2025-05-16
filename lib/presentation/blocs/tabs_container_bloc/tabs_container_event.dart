abstract class TabsContainerEvent {}

final class TabsContainerGetCurrentState extends TabsContainerEvent {}

final class TabsContainerChangeSelectedTab extends TabsContainerEvent {
  final int selectedIndex;

  TabsContainerChangeSelectedTab({required this.selectedIndex});
}
