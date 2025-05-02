abstract class TabContainerEvent {}

final class TabContainerGetCurrentState extends TabContainerEvent {
}

final class TabContainerChangeSelectedTab extends TabContainerEvent {
  final int selectedIndex;

  TabContainerChangeSelectedTab({required this.selectedIndex});
}
