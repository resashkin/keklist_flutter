import 'package:equatable/equatable.dart';
import 'package:keklist/domain/repositories/tabs/models/tabs_settings.dart';

abstract class TabsContainerEvent extends Equatable {
  const TabsContainerEvent();

  @override
  List<Object?> get props => const [];
}

final class TabsContainerGetCurrentState extends TabsContainerEvent {
  const TabsContainerGetCurrentState();
}

final class TabsContainerChangeSelectedTab extends TabsContainerEvent {
  final int selectedIndex;

  const TabsContainerChangeSelectedTab({required this.selectedIndex});

  @override
  List<Object?> get props => [selectedIndex];
}

final class TabsContainerSelectTab extends TabsContainerEvent {
  final TabType tabType;

  const TabsContainerSelectTab({required this.tabType});

  @override
  List<Object?> get props => [tabType];
}

final class TabsContainerUnselectTab extends TabsContainerEvent {
  final TabType tabType;

  const TabsContainerUnselectTab({required this.tabType});

  @override
  List<Object?> get props => [tabType];
}

final class TabsContainerReorderTabs extends TabsContainerEvent {
  final int oldIndex;
  final int newIndex;

  const TabsContainerReorderTabs({required this.oldIndex, required this.newIndex});

  @override
  List<Object?> get props => [oldIndex, newIndex];
}
