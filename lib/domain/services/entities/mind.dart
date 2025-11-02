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

  Mind copyWithNoteContent(MindNoteContent content) => copyWith(note: content.toRawNoteString());
  Mind appendAudioNote(String path, {String? separator}) =>
      copyWithNoteContent(noteContent.copyWithAppendedAudio(path, separator: separator));
}
