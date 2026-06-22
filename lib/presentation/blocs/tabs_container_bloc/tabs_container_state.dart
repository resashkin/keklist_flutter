import 'package:equatable/equatable.dart';
import 'package:keklist/domain/repositories/tabs/models/tabs_settings.dart';

final class TabsContainerState extends Equatable {
  final int selectedTabIndex;
  final List<TabModel> selectedTabs;
  final List<TabModel> hiddenTabs;

  const TabsContainerState({
    required this.selectedTabIndex,
    required this.selectedTabs,
    required this.hiddenTabs,
  });

  @override
  List<Object?> get props => [selectedTabIndex, selectedTabs, hiddenTabs];
}
