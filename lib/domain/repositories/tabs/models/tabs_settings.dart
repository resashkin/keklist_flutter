import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tabs_settings.g.dart';

@JsonSerializable()
final class TabsSettings with EquatableMixin {
  final List<TabModel> tabModels;
  final int defaultSelectedTabIndex;

  TabsSettings({
    required this.tabModels,
    required this.defaultSelectedTabIndex,
  });

  @override
  List<Object?> get props => [
        tabModels,
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

  @override
  List<Object?> get props => [this];

  @override
  bool? get stringify => true;
}
