part of 'emotion_bloc.dart';

@immutable
abstract class EmotionEvent with EquatableMixin {
  @override
  List<Object?> get props => [];
}

/// Re-emit the current emotions snapshot.
final class EmotionGetList extends EmotionEvent {}

final class EmotionCreate extends EmotionEvent {
  final String title;
  final String emoji;

  /// Parent emotion id, or `null` for a top-level emotion.
  final String? parentId;

  EmotionCreate({required this.title, required this.emoji, this.parentId});

  @override
  List<Object?> get props => [title, emoji, parentId];
}

final class EmotionUpdate extends EmotionEvent {
  final Emotion emotion;

  EmotionUpdate({required this.emotion});

  @override
  List<Object?> get props => [emotion];
}

/// Archive an emotion and its whole subtree — hides them from pickers while
/// keeping them resolvable on minds that already use them.
final class EmotionArchive extends EmotionEvent {
  final String id;

  EmotionArchive({required this.id});

  @override
  List<Object?> get props => [id];
}

/// Restore a single archived emotion (does not touch its subtree).
final class EmotionUnarchive extends EmotionEvent {
  final String id;

  EmotionUnarchive({required this.id});

  @override
  List<Object?> get props => [id];
}

/// Delete an emotion and its subtree. Any node still referenced by a mind is
/// archived instead of hard-deleted (and stripped from those minds if deleted).
final class EmotionDelete extends EmotionEvent {
  final String id;

  EmotionDelete({required this.id});

  @override
  List<Object?> get props => [id];
}

/// New ordering of sibling emotion ids (all sharing the same parent).
final class EmotionReorder extends EmotionEvent {
  final List<String> orderedEmotionIds;

  EmotionReorder({required this.orderedEmotionIds});

  @override
  List<Object?> get props => [orderedEmotionIds];
}

/// Move an emotion under [newParentId] (`null` = top level) at [index] among that
/// parent's children. Covers drag-reorder, nesting and promoting up a level.
final class EmotionMove extends EmotionEvent {
  final String id;
  final String? newParentId;
  final int index;

  EmotionMove({required this.id, required this.newParentId, required this.index});

  @override
  List<Object?> get props => [id, newParentId, index];
}

final class EmotionInternalGetListFromCache extends EmotionEvent {}
