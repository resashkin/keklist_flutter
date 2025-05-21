// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tabs_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TabsSettings _$TabsSettingsFromJson(Map<String, dynamic> json) => TabsSettings(
      selectedTabModels: (json['selectedTabModels'] as List<dynamic>)
          .map((e) => TabModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      defaultSelectedTabIndex: (json['defaultSelectedTabIndex'] as num).toInt(),
    );

Map<String, dynamic> _$TabsSettingsToJson(TabsSettings instance) =>
    <String, dynamic>{
      'selectedTabModels': instance.selectedTabModels,
      'defaultSelectedTabIndex': instance.defaultSelectedTabIndex,
    };

TabModel _$TabModelFromJson(Map<String, dynamic> json) => TabModel(
      type: $enumDecode(_$TabTypeEnumMap, json['type']),
    );

Map<String, dynamic> _$TabModelToJson(TabModel instance) => <String, dynamic>{
      'type': _$TabTypeEnumMap[instance.type]!,
    };

const _$TabTypeEnumMap = {
  TabType.calendar: 'calendar',
  TabType.insights: 'insights',
  TabType.settings: 'settings',
  TabType.profile: 'profile',
};
