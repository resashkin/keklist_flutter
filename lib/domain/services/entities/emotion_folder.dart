import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:keklist/domain/repositories/emotion/object/emotion_folder_object.dart';

part 'emotion_folder.g.dart';

/// A flat (single-level) grouping of [Emotion]s. Folders are title-only — they
/// carry no emoji. Ordering within the management screen and pickers is driven
/// by [orderIndex] for drag-and-drop.
@JsonSerializable()
final class EmotionFolder with EquatableMixin {
  final String id;
  final String title;
  final int orderIndex;
  final DateTime creationDate;

  const EmotionFolder({
    required this.id,
    required this.title,
    required this.orderIndex,
    required this.creationDate,
  });

  @override
  bool? get stringify => true;

  // JsonSerializable
  factory EmotionFolder.fromJson(Map<String, dynamic> json) => _$EmotionFolderFromJson(json);
  Map<String, dynamic> toJson() => _$EmotionFolderToJson(this);

  @override
  List<Object?> get props => [
        id,
        title,
        orderIndex,
        creationDate.millisecondsSinceEpoch,
      ];

  EmotionFolder copyWith({
    String? id,
    String? title,
    int? orderIndex,
    DateTime? creationDate,
  }) {
    return EmotionFolder(
      id: id ?? this.id,
      title: title ?? this.title,
      orderIndex: orderIndex ?? this.orderIndex,
      creationDate: creationDate ?? this.creationDate,
    );
  }

  EmotionFolderObject toObject() => EmotionFolderObject()
    ..id = id
    ..title = title
    ..orderIndex = orderIndex
    ..creationDate = creationDate;
}
