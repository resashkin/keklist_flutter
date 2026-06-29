part of 'emotion_bloc.dart';

sealed class EmotionState {}

/// The full snapshot of emotions (active + archived) and folders, each sorted
/// by [Emotion.orderIndex] / [EmotionFolder.orderIndex]. Consumers filter by
/// [Emotion.isArchived] and group by folder as needed.
final class EmotionsList extends EmotionState {
  final List<Emotion> emotions;
  final List<EmotionFolder> folders;

  EmotionsList({required this.emotions, required this.folders});

  List<Emotion> get activeEmotions => emotions.where((e) => !e.isArchived).toList();
  List<Emotion> get archivedEmotions => emotions.where((e) => e.isArchived).toList();

  /// Active, non-archived emotions that are not assigned to any folder.
  List<Emotion> get looseEmotions => activeEmotions.where((e) => e.folderIds.isEmpty).toList();

  /// Active, non-archived emotions assigned to [folderId].
  List<Emotion> emotionsInFolder(String folderId) =>
      activeEmotions.where((e) => e.folderIds.contains(folderId)).toList();
}
