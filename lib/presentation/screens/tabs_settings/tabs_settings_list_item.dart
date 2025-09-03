import 'package:keklist/domain/repositories/tabs/models/tabs_settings.dart';

sealed class TabsSettingsListItem {}

final class SectionHeaderItem extends TabsSettingsListItem {
  final String title;
  SectionHeaderItem(this.title);
}

final class DividerItem extends TabsSettingsListItem {}

final class SelectedTabItem extends TabsSettingsListItem {
  final TabModel tabModel;
  SelectedTabItem(this.tabModel);
}

final class HiddenTabItem extends TabsSettingsListItem {
  final TabModel tabModel;
  HiddenTabItem(this.tabModel);
}
