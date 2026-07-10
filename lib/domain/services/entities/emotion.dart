import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:keklist/domain/repositories/emotion/object/emotion_object.dart';

part 'emotion.g.dart';

/// A user-defined emotion that can be attached to a [Mind].
///
/// An emotion has a required [emoji] and [title]. Emotions form an unlimited-depth
/// tree via [parentId]: a `null` parent is a top-level (root) emotion, otherwise it
/// is a child of the emotion with that id. Any node — root or nested — can be
/// tagged on a mind.
///
/// Emotions are never hard-deleted while still referenced by minds; instead they
/// are [isArchived], which hides them from pickers while keeping them resolvable
/// on minds that already use them.
@JsonSerializable()
final class Emotion with EquatableMixin {
  final String id;
  final String title;
  final String emoji;
  final String? parentId;
  final bool isArchived;
  final int orderIndex;
  final DateTime creationDate;

  const Emotion({
    required this.id,
    required this.title,
    required this.emoji,
    required this.parentId,
    required this.isArchived,
    required this.orderIndex,
    required this.creationDate,
  });

  @override
  bool? get stringify => true;

  // JsonSerializable
  factory Emotion.fromJson(Map<String, dynamic> json) => _$EmotionFromJson(json);
  Map<String, dynamic> toJson() => _$EmotionToJson(this);

  @override
  List<Object?> get props => [
        id,
        title,
        emoji,
        parentId,
        isArchived,
        orderIndex,
        creationDate.millisecondsSinceEpoch,
      ];

  Emotion copyWith({
    String? id,
    String? title,
    String? emoji,
    String? parentId,
    bool? isArchived,
    int? orderIndex,
    DateTime? creationDate,
  }) {
    return Emotion(
      id: id ?? this.id,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      parentId: parentId ?? this.parentId,
      isArchived: isArchived ?? this.isArchived,
      orderIndex: orderIndex ?? this.orderIndex,
      creationDate: creationDate ?? this.creationDate,
    );
  }

  EmotionObject toObject() => EmotionObject()
    ..id = id
    ..title = title
    ..emoji = emoji
    ..parentId = parentId
    ..isArchived = isArchived
    ..orderIndex = orderIndex
    ..creationDate = creationDate;
}
