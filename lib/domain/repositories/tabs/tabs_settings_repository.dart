import 'dart:async';

import 'package:keklist/domain/repositories/tabs/models/tabs_settings.dart';

abstract class TabsSettingsRepository {
  TabsSettings get value;
  Stream<TabsSettings> get stream;

  FutureOr<void> update({required List<TabModel> selectedTabList});
  FutureOr<void> updateDefaultSelectedTabIndex({required int defaultSelectedTabIndex});
}
