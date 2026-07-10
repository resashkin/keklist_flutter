part of 'emotion_bloc.dart';

sealed class EmotionState {}

/// Full snapshot of all emotions (active + archived), sorted by [Emotion.orderIndex].
/// Emotions form a tree via [Emotion.parentId]; helpers below navigate it.
final class EmotionsList extends EmotionState {
  final List<Emotion> emotions;

  EmotionsList({required this.emotions});

  late final Map<String, Emotion> _byId = {for (final e in emotions) e.id: e};

  Emotion? byId(String id) => _byId[id];

  List<Emotion> get activeEmotions => emotions.where((e) => !e.isArchived).toList();
  List<Emotion> get archivedEmotions => emotions.where((e) => e.isArchived).toList();

  /// Active children of [parentId] (`null` → top-level roots), ordered.
  List<Emotion> childrenOf(String? parentId) =>
      activeEmotions.where((e) => e.parentId == parentId).toList()..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

  /// Top-level active emotions.
  List<Emotion> get rootEmotions => childrenOf(null);

  bool hasActiveChildren(String id) => activeEmotions.any((e) => e.parentId == id);

  /// All descendant ids of [id] (any archive state), at any depth.
  Set<String> descendantIdsOf(String id) {
    final result = <String>{};
    final queue = <String>[id];
    while (queue.isNotEmpty) {
      final parentId = queue.removeLast();
      for (final child in emotions.where((e) => e.parentId == parentId)) {
        if (result.add(child.id)) queue.add(child.id);
      }
    }
    return result;
  }

  /// Ancestors of [emotion] from root down to its direct parent (excludes itself).
  /// Resolves through archived nodes too so lineage still renders on tagged minds.
  List<Emotion> ancestorsOf(Emotion emotion) {
    final chain = <Emotion>[];
    var current = emotion.parentId == null ? null : _byId[emotion.parentId];
    final seen = <String>{};
    while (current != null && seen.add(current.id)) {
      chain.insert(0, current);
      current = current.parentId == null ? null : _byId[current.parentId];
    }
    return chain;
  }

  /// Lineage emojis for [emotion]: every ancestor emoji from root down, then its
  /// own — e.g. `['😄', '🕊️', '😌']` for Joy → Serenity → Calm.
  List<String> lineageEmojis(Emotion emotion) => [
        ...ancestorsOf(emotion).map((e) => e.emoji),
        emotion.emoji,
      ];
}
