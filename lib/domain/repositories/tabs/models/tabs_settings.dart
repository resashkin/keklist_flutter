import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';

part 'tabs_settings.g.dart';

@JsonSerializable()
final class TabsSettings with EquatableMixin {
  final List<TabModel> selectedTabModels;
  final int defaultSelectedTabIndex; // selected index when app starts

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

  String localizedLabel(BuildContext context) => switch (this) {
        TabType.calendar => context.l10n.calendar,
        TabType.insights => context.l10n.insights,
        TabType.settings => context.l10n.settings,
        TabType.profile => context.l10n.profile,
        TabType.today => context.l10n.today,
        TabType.debugMenu => context.l10n.debugMenu
      };

  String localizedDescription(BuildContext context) => switch (this) {
        TabType.calendar => context.l10n.calendarDescription,
        TabType.insights => context.l10n.insightsDescription,
        TabType.settings => context.l10n.settingsDescription,
        TabType.profile => context.l10n.profileDescription,
        TabType.today => context.l10n.todayDescription,
        TabType.debugMenu => context.l10n.debugMenuDescription
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
