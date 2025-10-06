import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:keklist/domain/services/entities/mind.dart';

part 'user_content.g.dart';

///
/// Model to hold all data from local user.
///
/// Using:
/// - Export/Import data

@JsonSerializable()
final class UserContent {
  final List<Mind> minds;

  UserContent({required this.minds});

  // JsonSerializable
  factory UserContent.fromJson(Map<String, dynamic> json) => _$UserContentFromJson(json);
  Map<String, dynamic> toJson() => _$UserContentToJson(this);

  // To make string from data for import/export
  String toBase64Message() {
    final String jsonMessage = jsonEncode(toJson());
    final String base64Message = base64.encode(utf8.encode(jsonMessage));
    return base64Message;
  }

  static UserContent fromBase64Message(String base64Message) {
    final String jsonMessage = utf8.decode(base64.decode(base64Message));
    final Map<String, dynamic> json = jsonDecode(jsonMessage);
    return UserContent.fromJson(json);
  }
}
