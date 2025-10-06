// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mind.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Mind _$MindFromJson(Map<String, dynamic> json) => Mind(
      id: json['id'] as String,
      note: json['note'] as String,
      emoji: json['emoji'] as String,
      dayIndex: (json['dayIndex'] as num).toInt(),
      creationDate: DateTime.parse(json['creationDate'] as String),
      sortIndex: (json['sortIndex'] as num).toInt(),
      rootId: json['rootId'] as String?,
    );

Map<String, dynamic> _$MindToJson(Mind instance) => <String, dynamic>{
      'id': instance.id,
      'emoji': instance.emoji,
      'note': instance.note,
      'dayIndex': instance.dayIndex,
      'creationDate': instance.creationDate.toIso8601String(),
      'sortIndex': instance.sortIndex,
      'rootId': instance.rootId,
    };
