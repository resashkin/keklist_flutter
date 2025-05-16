import 'dart:async';

import 'package:keklist/domain/repositories/tabs/models/tabs_settings.dart';

abstract class TabsSettingsRepository {
  TabsSettings get value;
  Stream<TabsSettings> get stream;

  FutureOr<void> updateTabList({required List<TabModel> tabList});
  FutureOr<void> updateDefaultSelectedTabIndex({required List<TabModel> defaultSelectedTabIndex});
}
