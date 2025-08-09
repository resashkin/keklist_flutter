import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tabs_settings.g.dart';

@JsonSerializable()
final class TabsSettings with EquatableMixin {
  final List<TabModel> selectedTabModels;
  final int defaultSelectedTabIndex; // selected index when user login

  TabsSettings({
    required this.selectedTabModels,
    required this.defaultSelectedTabIndex,
  });

  @override
  List<Object?> get props => [
        selectedTabModels,
        defaultSelectedTabIndex,
      ];

  @override
  bool? get stringify => true;

  // JsonSerializable
  factory TabsSettings.fromJson(Map<String, dynamic> json) => _$TabsSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$TabsSettingsToJson(this);
}

@JsonSerializable()
final class TabModel with EquatableMixin {
  final TabType type;

  TabModel({required this.type});

  @override
  List<Object?> get props => [type];

  @override
  bool? get stringify => true;

  // JsonSerializable
  factory TabModel.fromJson(Map<String, dynamic> json) => _$TabModelFromJson(json);
  Map<String, dynamic> toJson() => _$TabModelToJson(this);
}

@JsonEnum()
enum TabType implements Equatable {
  calendar,
  insights,
  settings,
  profile,
  today,
  debugMenu;

  String get label => switch (this) {
        TabType.calendar => 'Calendar',
        TabType.insights => 'Insights',
        TabType.settings => 'Settings',
        TabType.profile => 'Profile',
        TabType.today => 'Today',
        TabType.debugMenu => 'Debug Menu'
      };

  String get description => switch (this) {
        TabType.calendar => 'Main screen with Calendar of entries',
        TabType.insights => 'Statistics all yours entries',
        TabType.settings => 'Screen with all settings (dark mode, sync and etc.)',
        TabType.profile => 'Screen with your profile',
        TabType.today => 'Only today minds',
        TabType.debugMenu => 'Developer tools for toggling experimental features'
      };

  Icon get materialIcon => switch (this) {
        TabType.calendar => Icon(Icons.calendar_month),
        TabType.insights => Icon(Icons.insights),
        TabType.profile => Icon(Icons.person),
        TabType.settings => Icon(Icons.settings),
        TabType.today => Icon(Icons.today),
        TabType.debugMenu => Icon(Icons.bug_report)
      };

  @override
  List<Object?> get props => [this];

  @override
  bool? get stringify => true;
}
