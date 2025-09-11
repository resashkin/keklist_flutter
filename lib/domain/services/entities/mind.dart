import 'package:equatable/equatable.dart';
import 'package:keklist/domain/repositories/mind/object/mind_object.dart';

final class Mind with EquatableMixin {
  final String id;
  final String emoji;
  final String note;
  final int dayIndex;
  final DateTime creationDate;
  final int sortIndex;
  final String? rootId;

  Mind({
    required this.id,
    required this.note,
    required this.emoji,
    required this.dayIndex,
    required this.creationDate,
    required this.sortIndex,
    required this.rootId,
  });

  @override
  bool? get stringify => true;

  @override
  List<Object?> get props => [
        id,
        emoji,
        note,
        sortIndex,
        dayIndex,
        creationDate.millisecondsSinceEpoch,
      ];

  Map<String, dynamic> toShortJson() => {
        'uuid': id,
        'emoji': emoji,
        'note': note,
        'day_index': dayIndex,
        'sort_index': sortIndex,
      };

  List<String> toCSVEntry() => [
        id,
        emoji,
        note,
        dayIndex.toString(),
        sortIndex.toString(),
        creationDate.toString(),
        rootId?.toString() ?? "null",
      ];

  Mind copyWith({
    String? id,
    String? emoji,
    String? note,
    int? dayIndex,
    DateTime? creationDate,
    int? sortIndex,
    String? rootId,
  }) {
    return Mind(
      id: id ?? this.id,
      emoji: emoji ?? this.emoji,
      note: note ?? this.note,
      dayIndex: dayIndex ?? this.dayIndex,
      creationDate: creationDate ?? this.creationDate,
      sortIndex: sortIndex ?? this.sortIndex,
      rootId: rootId ?? this.rootId,
    );
  }

  MindObject toObject() => MindObject()
    ..id = id
    ..emoji = emoji
    ..note = note
    ..dayIndex = dayIndex
    ..creationDate = creationDate
    ..sortIndex = sortIndex
    ..rootId = rootId;
}
