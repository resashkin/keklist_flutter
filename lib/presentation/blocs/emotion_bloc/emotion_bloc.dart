import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:keklist/domain/repositories/emotion/emotion_repository.dart';
import 'package:keklist/domain/repositories/mind/mind_repository.dart';
import 'package:keklist/domain/services/entities/emotion.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';
import 'package:uuid/uuid.dart';

part 'emotion_event.dart';
part 'emotion_state.dart';

final class EmotionBloc extends Bloc<EmotionEvent, EmotionState> with DisposeBag {
  final EmotionRepository _emotionRepository;
  final MindRepository _mindRepository;
  final Uuid _uuid = const Uuid();

  EmotionBloc({
    required EmotionRepository emotionRepository,
    required MindRepository mindRepository,
  })  : _emotionRepository = emotionRepository,
        _mindRepository = mindRepository,
        super(EmotionsList(emotions: const [])) {
    on<EmotionGetList>((_, emit) => _emitList(emit));
    on<EmotionInternalGetListFromCache>((_, emit) => _emitList(emit));
    on<EmotionCreate>(_createEmotion);
    on<EmotionUpdate>(_updateEmotion);
    on<EmotionArchive>(_archiveEmotion);
    on<EmotionUnarchive>(_unarchiveEmotion);
    on<EmotionDelete>(_deleteEmotion);
    on<EmotionReorder>(_reorderEmotions);
    on<EmotionMove>(_moveEmotion);

    _emotionRepository.stream.listen((_) => add(EmotionInternalGetListFromCache())).disposed(by: this);
  }

  @override
  Future<void> close() {
    cancelSubscriptions();
    return super.close();
  }

  void _emitList(Emitter<EmotionState> emit) {
    final emotions = _emotionRepository.values.toList()..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    emit(EmotionsList(emotions: emotions));
  }

  /// Next order index within a sibling group (emotions sharing [parentId]).
  int _nextOrderIndex(String? parentId) {
    final siblings = _emotionRepository.values.where((e) => e.parentId == parentId);
    return siblings.isEmpty ? 0 : siblings.map((e) => e.orderIndex).reduce((a, b) => a > b ? a : b) + 1;
  }

  bool _isEmotionReferenced(String id) => _mindRepository.values.any((mind) => mind.emotionIds.contains(id));

  /// [id] plus all of its descendants (any archive state), deepest last.
  List<Emotion> _subtree(String id) {
    final all = _emotionRepository.values.toList();
    final result = <Emotion>[];
    final root = all.firstWhere((e) => e.id == id, orElse: () => _sentinel);
    if (identical(root, _sentinel)) return result;
    result.add(root);
    final queue = <String>[id];
    while (queue.isNotEmpty) {
      final parentId = queue.removeLast();
      for (final child in all.where((e) => e.parentId == parentId)) {
        result.add(child);
        queue.add(child.id);
      }
    }
    return result;
  }

  Future<void> _stripEmotionFromMinds(String id) async {
    final affected = _mindRepository.values
        .where((mind) => mind.emotionIds.contains(id))
        .map((mind) => mind.copyWith(emotionIds: mind.emotionIds.where((e) => e != id).toList()))
        .toList();
    if (affected.isNotEmpty) {
      await _mindRepository.updateMinds(minds: affected);
    }
  }

  Future<void> _createEmotion(EmotionCreate event, Emitter<EmotionState> emit) async {
    final emotion = Emotion(
      id: _uuid.v4(),
      title: event.title.trim(),
      emoji: event.emoji,
      parentId: event.parentId,
      isArchived: false,
      orderIndex: _nextOrderIndex(event.parentId),
      creationDate: DateTime.now().toUtc(),
    );
    await _emotionRepository.createEmotion(emotion: emotion);
  }

  Future<void> _updateEmotion(EmotionUpdate event, Emitter<EmotionState> emit) async {
    await _emotionRepository.updateEmotion(emotion: event.emotion);
  }

  /// Archive the emotion and its whole subtree.
  Future<void> _archiveEmotion(EmotionArchive event, Emitter<EmotionState> emit) async {
    final subtree = _subtree(event.id).where((e) => !e.isArchived).map((e) => e.copyWith(isArchived: true)).toList();
    if (subtree.isNotEmpty) {
      await _emotionRepository.updateEmotions(emotions: subtree);
    }
  }

  Future<void> _unarchiveEmotion(EmotionUnarchive event, Emitter<EmotionState> emit) async {
    final emotion = await _emotionRepository.obtainEmotion(id: event.id);
    if (emotion == null) return;
    await _emotionRepository.updateEmotion(emotion: emotion.copyWith(isArchived: false));
  }

  /// Delete the emotion and its subtree. Nodes still referenced by minds are
  /// archived instead of hard-deleted; unreferenced nodes are deleted and
  /// stripped from minds.
  Future<void> _deleteEmotion(EmotionDelete event, Emitter<EmotionState> emit) async {
    final subtree = _subtree(event.id);
    final toArchive = <Emotion>[];
    for (final node in subtree) {
      if (_isEmotionReferenced(node.id)) {
        if (!node.isArchived) toArchive.add(node.copyWith(isArchived: true));
      } else {
        await _stripEmotionFromMinds(node.id);
        await _emotionRepository.deleteEmotion(id: node.id);
      }
    }
    if (toArchive.isNotEmpty) {
      await _emotionRepository.updateEmotions(emotions: toArchive);
    }
  }

  /// Persist a new sibling ordering (the ids share one parent).
  Future<void> _reorderEmotions(EmotionReorder event, Emitter<EmotionState> emit) async {
    final updated = <Emotion>[];
    for (int i = 0; i < event.orderedEmotionIds.length; i++) {
      final emotion = await _emotionRepository.obtainEmotion(id: event.orderedEmotionIds[i]);
      if (emotion != null && emotion.orderIndex != i) {
        updated.add(emotion.copyWith(orderIndex: i));
      }
    }
    if (updated.isNotEmpty) {
      await _emotionRepository.updateEmotions(emotions: updated);
    }
  }

  /// Move [event.id] under [event.newParentId] (null = top level) at [event.index]
  /// among that parent's children, reindexing the destination siblings. Handles
  /// reorder (same parent), nest (parent is another emotion) and promote (parent
  /// is an ancestor). Refuses to move an emotion into its own subtree.
  Future<void> _moveEmotion(EmotionMove event, Emitter<EmotionState> emit) async {
    final all = _emotionRepository.values.toList();
    final moved = all.firstWhereOrNull((e) => e.id == event.id);
    if (moved == null || event.newParentId == moved.id) return;

    if (event.newParentId != null) {
      final subtree = <String>{};
      final queue = <String>[moved.id];
      while (queue.isNotEmpty) {
        final parentId = queue.removeLast();
        for (final child in all.where((e) => e.parentId == parentId)) {
          if (subtree.add(child.id)) queue.add(child.id);
        }
      }
      if (subtree.contains(event.newParentId)) return; // would create a cycle
    }

    final siblings = all.where((e) => e.parentId == event.newParentId && e.id != moved.id).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final int idx = event.index.clamp(0, siblings.length);
    final ordered = [...siblings.sublist(0, idx), moved, ...siblings.sublist(idx)];

    final updates = <Emotion>[];
    for (int i = 0; i < ordered.length; i++) {
      final s = ordered[i];
      if (s.id == moved.id) {
        if (s.parentId != event.newParentId || s.orderIndex != i) {
          updates.add(Emotion(
            id: s.id,
            title: s.title,
            emoji: s.emoji,
            parentId: event.newParentId,
            isArchived: s.isArchived,
            orderIndex: i,
            creationDate: s.creationDate,
          ));
        }
      } else if (s.orderIndex != i) {
        updates.add(s.copyWith(orderIndex: i));
      }
    }
    if (updates.isNotEmpty) await _emotionRepository.updateEmotions(emotions: updates);
  }

  static final Emotion _sentinel = Emotion(
    id: '',
    title: '',
    emoji: '',
    parentId: null,
    isArchived: false,
    orderIndex: 0,
    creationDate: DateTime.fromMillisecondsSinceEpoch(0),
  );
}
