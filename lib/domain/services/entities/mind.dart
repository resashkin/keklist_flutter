import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:keklist/domain/repositories/mind/object/mind_object.dart';
import 'package:keklist/domain/services/entities/mind_note_content.dart';

part 'mind.g.dart';

@JsonSerializable()
final class Mind with EquatableMixin {
  final String id;
  final String emoji;
  final String note; // TODO: rename to rawNote
  final int dayIndex;
  final DateTime creationDate;
  final int sortIndex;
  final String? rootId;
  final List<String> emotionIds;

  @override
  bool? get stringify => true;

  String get plainNote => noteContent.plainText;
  MindNoteContent get noteContent => MindNoteContent.parse(note);
  List<MindNoteAudio> get audioNotes => noteContent.audioPieces;

  Mind({
    required this.id,
    required this.note,
    required this.emoji,
    required this.dayIndex,
    required this.creationDate,
    required this.sortIndex,
    required this.rootId,
    this.emotionIds = const [],
  });

  // JsonSerializable
  factory Mind.fromJson(Map<String, dynamic> json) => _$MindFromJson(json);
  Map<String, dynamic> toJson() => _$MindToJson(this);

  @override
  List<Object?> get props => [
        id,
        emoji,
        note,
        sortIndex,
        dayIndex,
        rootId,
        emotionIds,
        creationDate.millisecondsSinceEpoch,
      ];

  Map<String, dynamic> toShortJson() => {
        'uuid': id,
        'emoji': emoji,
        'note': note,
        'day_index': dayIndex,
        'sort_index': sortIndex,
      };

  /// Positional, header-less row. Columns are only ever appended: readers guard
  /// on length, so an older build ignores trailing fields it does not know.
  /// Ids are joined with `,` because the CSV field delimiter is `;`.
  List<String> toCSVEntry() => [
        id,
        emoji,
        note,
        dayIndex.toString(),
        sortIndex.toString(),
        creationDate.toString(),
        rootId?.toString() ?? "null",
        emotionIds.join(','),
      ];

  /// Parses the emotion id column of a [toCSVEntry] row, tolerating rows written
  /// before the column existed.
  static List<String> emotionIdsFromCSVEntry(List<dynamic> row) {
    if (row.length <= 7) return const [];
    return row[7].toString().split(',').map((id) => id.trim()).where((id) => id.isNotEmpty).toList();
  }

  Mind copyWith({
    String? id,
    String? emoji,
    String? note,
    int? dayIndex,
    DateTime? creationDate,
    int? sortIndex,
    String? rootId,
    List<String>? emotionIds,
  }) {
    return Mind(
      id: id ?? this.id,
      emoji: emoji ?? this.emoji,
      note: note ?? this.note,
      dayIndex: dayIndex ?? this.dayIndex,
      creationDate: creationDate ?? this.creationDate,
      sortIndex: sortIndex ?? this.sortIndex,
      rootId: rootId ?? this.rootId,
      emotionIds: emotionIds ?? this.emotionIds,
    );
  }

  MindObject toObject() => MindObject()
    ..id = id
    ..emoji = emoji
    ..note = note
    ..dayIndex = dayIndex
    ..creationDate = creationDate
    ..sortIndex = sortIndex
    ..rootId = rootId
    ..emotionIds = emotionIds;

  Mind copyWithNoteContent(MindNoteContent content) => copyWith(note: content.toRawNoteString());
  Mind appendAudioNote(String path, {String? separator, double? durationSeconds}) =>
      copyWithNoteContent(noteContent.copyWithAppendedAudio(path, separator: separator, durationSeconds: durationSeconds));
}
