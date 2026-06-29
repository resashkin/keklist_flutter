import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:keklist/domain/repositories/emotion/object/emotion_object.dart';

part 'emotion.g.dart';

/// A user-defined emotion that can be attached to a [Mind].
///
/// An emotion has a required [emoji] and [title]. It can optionally belong to
/// one or more folders ([folderIds]) — the UI currently assigns a single folder,
/// but storage supports many to keep the model future-proof.
///
/// Emotions are never hard-deleted while still referenced by minds; instead they
/// are [isArchived], which hides them from pickers while keeping them resolvable
/// on minds that already use them.
@JsonSerializable()
final class Emotion with EquatableMixin {
  final String id;
  final String title;
  final String emoji;
  final List<String> folderIds;
  final bool isArchived;
  final int orderIndex;
  final DateTime creationDate;

  const Emotion({
    required this.id,
    required this.title,
    required this.emoji,
    required this.folderIds,
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
        folderIds,
        isArchived,
        orderIndex,
        creationDate.millisecondsSinceEpoch,
      ];

  Emotion copyWith({
    String? id,
    String? title,
    String? emoji,
    List<String>? folderIds,
    bool? isArchived,
    int? orderIndex,
    DateTime? creationDate,
  }) {
    return Emotion(
      id: id ?? this.id,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      folderIds: folderIds ?? this.folderIds,
      isArchived: isArchived ?? this.isArchived,
      orderIndex: orderIndex ?? this.orderIndex,
      creationDate: creationDate ?? this.creationDate,
    );
  }

  EmotionObject toObject() => EmotionObject()
    ..id = id
    ..title = title
    ..emoji = emoji
    ..folderIds = folderIds
    ..isArchived = isArchived
    ..orderIndex = orderIndex
    ..creationDate = creationDate;
}
