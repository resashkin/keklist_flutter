final class TabContainerState {
  final int selectedTabIndex;
  final List<TabModel> tabs;

  const TabContainerState({
    required this.selectedTabIndex,
    required this.tabs,
  });
}

final class TabModel {
  final TabType type;

  TabModel({required this.type});
}

enum TabType {
  calendar,
  insights,
  settings,
  profile;

  String get label {
    switch (this) {
      case TabType.calendar:
        return 'Calendar';
      case TabType.insights:
        return 'Insights';
      case TabType.settings:
        return 'Settings';
      case TabType.profile:
        return 'Profile';
    }
  }
}
