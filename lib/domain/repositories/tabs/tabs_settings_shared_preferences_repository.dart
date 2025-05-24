import 'dart:async';

import 'package:keklist/domain/repositories/tabs/models/tabs_settings.dart';
import 'package:keklist/domain/repositories/tabs/tabs_settings_repository.dart';
import 'package:rxdart/rxdart.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

final class TabsSettingsSharedPreferencesRepository extends TabsSettingsRepository {
  final StreamingSharedPreferences _preferences;
  final Preference<TabsSettings?> _tabsSettingsPreferences;
  final BehaviorSubject<TabsSettings> _behaviorSubject = BehaviorSubject<TabsSettings>();

  @override
  Stream<TabsSettings> get stream => _behaviorSubject;

  @override
  TabsSettings get value =>
      _behaviorSubject.valueOrNull ??
      TabsSettings(
        selectedTabModels: [],
        defaultSelectedTabIndex: 0,
      );

  TabsSettingsSharedPreferencesRepository({required StreamingSharedPreferences preferences})
      : _preferences = preferences,
        _tabsSettingsPreferences = preferences.getCustomValue<TabsSettings?>(
          'tabs_settings',
          defaultValue: null,
          adapter: JsonAdapter<TabsSettings>(
            deserializer: (jsonObject) {
              final Map<String, dynamic> json = (jsonObject as Map<String, dynamic>);
              return TabsSettings.fromJson(json);
            },
          ),
        ) {
    _behaviorSubject.addStream(
      _tabsSettingsPreferences.asBroadcastStream().whereNotNull().debounceTime(const Duration(milliseconds: 10)),
    );
  }

  @override
  FutureOr<void> setDefaultTabs() {
    _updateSettings(
      TabsSettings(
        defaultSelectedTabIndex: 0,
        selectedTabModels: [
          TabModel(type: TabType.calendar),
          TabModel(type: TabType.insights),
          TabModel(type: TabType.profile),
        ],
      ),
    );
  }

  @override
  FutureOr<void> updateDefaultSelectedTabIndex({required int defaultSelectedTabIndex}) {
    return _updateSettings(TabsSettings(
      selectedTabModels: _tabsSettingsPreferences.getValue()?.selectedTabModels ?? [],
      defaultSelectedTabIndex: defaultSelectedTabIndex,
    ));
  }

  @override
  FutureOr<void> update({required List<TabModel> selectedTabList}) {
    return _updateSettings(TabsSettings(
      selectedTabModels: selectedTabList,
      defaultSelectedTabIndex: _tabsSettingsPreferences.getValue()?.defaultSelectedTabIndex ?? 0,
    ));
  }

  FutureOr<void> _updateSettings(TabsSettings settings) async {
    _preferences.setCustomValue(
      'tabs_settings',
      settings,
      adapter: JsonAdapter<TabsSettings>(),
    );
  }
}
