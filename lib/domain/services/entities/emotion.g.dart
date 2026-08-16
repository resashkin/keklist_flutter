// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emotion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Emotion _$EmotionFromJson(Map<String, dynamic> json) => Emotion(
  id: json['id'] as String,
  title: json['title'] as String,
  emoji: json['emoji'] as String,
  parentId: json['parentId'] as String?,
  isArchived: json['isArchived'] as bool,
  orderIndex: (json['orderIndex'] as num).toInt(),
  creationDate: DateTime.parse(json['creationDate'] as String),
);

Map<String, dynamic> _$EmotionToJson(Emotion instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'emoji': instance.emoji,
  'parentId': instance.parentId,
  'isArchived': instance.isArchived,
  'orderIndex': instance.orderIndex,
  'creationDate': instance.creationDate.toIso8601String(),
};
