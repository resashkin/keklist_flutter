// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_content.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserContent _$UserContentFromJson(Map<String, dynamic> json) => UserContent(
      minds: (json['minds'] as List<dynamic>)
          .map((e) => Mind.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UserContentToJson(UserContent instance) =>
    <String, dynamic>{
      'minds': instance.minds,
    };
