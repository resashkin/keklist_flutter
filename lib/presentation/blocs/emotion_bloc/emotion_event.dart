part of 'emotion_bloc.dart';

@immutable
abstract class EmotionEvent with EquatableMixin {
  @override
  List<Object?> get props => [];
}

/// Re-emit the current emotions + folders snapshot.
final class EmotionGetList extends EmotionEvent {}

final class EmotionCreate extends EmotionEvent {
  final String title;
  final String emoji;

  /// Single folder assignment from the UI (storage still supports many).
  final String? folderId;

  EmotionCreate({required this.title, required this.emoji, this.folderId});

  @override
  List<Object?> get props => [title, emoji, folderId];
}

final class EmotionUpdate extends EmotionEvent {
  final Emotion emotion;

  EmotionUpdate({required this.emotion});

  @override
  List<Object?> get props => [emotion];
}

/// Hide an emotion from pickers while keeping it resolvable on tagged minds.
final class EmotionArchive extends EmotionEvent {
  final String id;

  EmotionArchive({required this.id});

  @override
  List<Object?> get props => [id];
}

final class EmotionUnarchive extends EmotionEvent {
  final String id;

  EmotionUnarchive({required this.id});

  @override
  List<Object?> get props => [id];
}

/// Permanently delete an emotion and strip its id from every mind.
final class EmotionDelete extends EmotionEvent {
  final String id;

  EmotionDelete({required this.id});

  @override
  List<Object?> get props => [id];
}

/// New ordering of emotion ids within a single section (loose or one folder).
final class EmotionReorder extends EmotionEvent {
  final List<String> orderedEmotionIds;

  EmotionReorder({required this.orderedEmotionIds});

  @override
  List<Object?> get props => [orderedEmotionIds];
}

final class EmotionFolderCreate extends EmotionEvent {
  final String title;

  EmotionFolderCreate({required this.title});

  @override
  List<Object?> get props => [title];
}

final class EmotionFolderUpdate extends EmotionEvent {
  final EmotionFolder folder;

  EmotionFolderUpdate({required this.folder});

  @override
  List<Object?> get props => [folder];
}

/// Delete a folder. Emotions inside it are archived (if referenced by minds)
/// or permanently deleted (if not), matching the single-emotion rule.
final class EmotionFolderDelete extends EmotionEvent {
  final String id;

  EmotionFolderDelete({required this.id});

  @override
  List<Object?> get props => [id];
}

final class EmotionFolderReorder extends EmotionEvent {
  final List<String> orderedFolderIds;

  EmotionFolderReorder({required this.orderedFolderIds});

  @override
  List<Object?> get props => [orderedFolderIds];
}

final class EmotionInternalGetListFromCache extends EmotionEvent {}
