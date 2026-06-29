// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emotion_folder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmotionFolder _$EmotionFolderFromJson(Map<String, dynamic> json) =>
    EmotionFolder(
      id: json['id'] as String,
      title: json['title'] as String,
      orderIndex: (json['orderIndex'] as num).toInt(),
      creationDate: DateTime.parse(json['creationDate'] as String),
    );

Map<String, dynamic> _$EmotionFolderToJson(EmotionFolder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'orderIndex': instance.orderIndex,
      'creationDate': instance.creationDate.toIso8601String(),
    };
