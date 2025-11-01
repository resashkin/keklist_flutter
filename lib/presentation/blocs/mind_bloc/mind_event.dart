part of 'mind_bloc.dart';

@immutable
abstract class MindEvent with EquatableMixin {
  @override
  List<Object?> get props => [];
}

final class MindGetList extends MindEvent {}

final class MindCreate extends MindEvent {
  final int dayIndex;
  final String emoji;
  final String? rootId;
  final List<BaseMindNotePiece> mindContent;

  MindCreate({
    required this.dayIndex,
    required List<BaseMindNotePiece> mindContent,
    required this.emoji,
    required this.rootId,
  }) : mindContent = List<BaseMindNotePiece>.unmodifiable(mindContent);

  @override
  List<Object?> get props => [dayIndex, mindContent, emoji, rootId];
}

final class MindDelete extends MindEvent {
  final Mind mind;

  MindDelete({required this.mind});

  @override
  List<Object?> get props => [mind];
}

final class MindEdit extends MindEvent {
  final Mind mind;

  @override
  List<Object?> get props => [mind];

  MindEdit({required this.mind});
}

final class MindEditNote extends MindEvent {
  final String uuid;
  final String newNote;

  @override
  List<Object?> get props => [uuid, newNote];

  MindEditNote({
    required this.uuid,
    required this.newNote,
  });
}

final class MindEditEmoji extends MindEvent {
  final String uuid;
  final String newEmoji;

  @override
  List<Object?> get props => [uuid, newEmoji];

  MindEditEmoji({
    required this.uuid,
    required this.newEmoji,
  });
}

final class MindMove extends MindEvent {}

final class MindCopyToNow extends MindEvent {}

final class MindStartSearch extends MindEvent {}

final class MindEnterSearchText extends MindEvent {
  final String text;

  MindEnterSearchText({required this.text});

  @override
  List<Object?> get props => [text];
}

final class MindStopSearch extends MindEvent {}

final class MindClearCache extends MindEvent {}

final class MindInternalGetListFromCache extends MindEvent {}

final class MindGetTransactionList extends MindEvent {}

final class MindUpdateMobileWidgets extends MindEvent {}
