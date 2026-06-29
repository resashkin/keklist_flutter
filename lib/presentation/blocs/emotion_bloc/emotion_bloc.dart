import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:keklist/domain/repositories/emotion/emotion_folder_repository.dart';
import 'package:keklist/domain/repositories/emotion/emotion_repository.dart';
import 'package:keklist/domain/repositories/mind/mind_repository.dart';
import 'package:keklist/domain/services/entities/emotion.dart';
import 'package:keklist/domain/services/entities/emotion_folder.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';
import 'package:uuid/uuid.dart';

part 'emotion_event.dart';
part 'emotion_state.dart';

final class EmotionBloc extends Bloc<EmotionEvent, EmotionState> with DisposeBag {
  final EmotionRepository _emotionRepository;
  final EmotionFolderRepository _folderRepository;
  final MindRepository _mindRepository;
  final Uuid _uuid = const Uuid();

  EmotionBloc({
    required EmotionRepository emotionRepository,
    required EmotionFolderRepository folderRepository,
    required MindRepository mindRepository,
  })  : _emotionRepository = emotionRepository,
        _folderRepository = folderRepository,
        _mindRepository = mindRepository,
        super(EmotionsList(emotions: const [], folders: const [])) {
    on<EmotionGetList>((_, emit) => _emitList(emit));
    on<EmotionInternalGetListFromCache>((_, emit) => _emitList(emit));
    on<EmotionCreate>(_createEmotion);
    on<EmotionUpdate>(_updateEmotion);
    on<EmotionArchive>(_archiveEmotion);
    on<EmotionUnarchive>(_unarchiveEmotion);
    on<EmotionDelete>(_deleteEmotion);
    on<EmotionReorder>(_reorderEmotions);
    on<EmotionFolderCreate>(_createFolder);
    on<EmotionFolderUpdate>(_updateFolder);
    on<EmotionFolderDelete>(_deleteFolder);
    on<EmotionFolderReorder>(_reorderFolders);

    _emotionRepository.stream.listen((_) => add(EmotionInternalGetListFromCache())).disposed(by: this);
    _folderRepository.stream.listen((_) => add(EmotionInternalGetListFromCache())).disposed(by: this);
  }

  @override
  Future<void> close() {
    cancelSubscriptions();
    return super.close();
  }

  void _emitList(Emitter<EmotionState> emit) {
    final emotions = _emotionRepository.values.toList()..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final folders = _folderRepository.values.toList()..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    emit(EmotionsList(emotions: emotions, folders: folders));
  }

  int _nextEmotionOrderIndex() => (_emotionRepository.values.map((e) => e.orderIndex).fold<int>(-1, max)) + 1;
  int _nextFolderOrderIndex() => (_folderRepository.values.map((f) => f.orderIndex).fold<int>(-1, max)) + 1;

  bool _isEmotionReferenced(String id) => _mindRepository.values.any((mind) => mind.emotionIds.contains(id));

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
      folderIds: event.folderId == null ? const [] : [event.folderId!],
      isArchived: false,
      orderIndex: _nextEmotionOrderIndex(),
      creationDate: DateTime.now().toUtc(),
    );
    await _emotionRepository.createEmotion(emotion: emotion);
  }

  Future<void> _updateEmotion(EmotionUpdate event, Emitter<EmotionState> emit) async {
    await _emotionRepository.updateEmotion(emotion: event.emotion);
  }

  Future<void> _archiveEmotion(EmotionArchive event, Emitter<EmotionState> emit) async {
    final emotion = await _emotionRepository.obtainEmotion(id: event.id);
    if (emotion == null) return;
    await _emotionRepository.updateEmotion(emotion: emotion.copyWith(isArchived: true));
  }

  Future<void> _unarchiveEmotion(EmotionUnarchive event, Emitter<EmotionState> emit) async {
    final emotion = await _emotionRepository.obtainEmotion(id: event.id);
    if (emotion == null) return;
    await _emotionRepository.updateEmotion(emotion: emotion.copyWith(isArchived: false));
  }

  Future<void> _deleteEmotion(EmotionDelete event, Emitter<EmotionState> emit) async {
    await _stripEmotionFromMinds(event.id);
    await _emotionRepository.deleteEmotion(id: event.id);
  }

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

  Future<void> _createFolder(EmotionFolderCreate event, Emitter<EmotionState> emit) async {
    final folder = EmotionFolder(
      id: _uuid.v4(),
      title: event.title.trim(),
      orderIndex: _nextFolderOrderIndex(),
      creationDate: DateTime.now().toUtc(),
    );
    await _folderRepository.createFolder(folder: folder);
  }

  Future<void> _updateFolder(EmotionFolderUpdate event, Emitter<EmotionState> emit) async {
    await _folderRepository.updateFolder(folder: event.folder);
  }

  Future<void> _deleteFolder(EmotionFolderDelete event, Emitter<EmotionState> emit) async {
    // Cascade: archive contents that are still referenced by minds, delete the rest.
    final contents = _emotionRepository.values.where((e) => e.folderIds.contains(event.id)).toList();
    for (final emotion in contents) {
      final remainingFolderIds = emotion.folderIds.where((id) => id != event.id).toList();
      if (_isEmotionReferenced(emotion.id)) {
        await _emotionRepository.updateEmotion(
          emotion: emotion.copyWith(isArchived: true, folderIds: remainingFolderIds),
        );
      } else {
        await _stripEmotionFromMinds(emotion.id);
        await _emotionRepository.deleteEmotion(id: emotion.id);
      }
    }
    await _folderRepository.deleteFolder(id: event.id);
  }

  Future<void> _reorderFolders(EmotionFolderReorder event, Emitter<EmotionState> emit) async {
    final updated = <EmotionFolder>[];
    for (int i = 0; i < event.orderedFolderIds.length; i++) {
      final folder = await _folderRepository.obtainFolder(id: event.orderedFolderIds[i]);
      if (folder != null && folder.orderIndex != i) {
        updated.add(folder.copyWith(orderIndex: i));
      }
    }
    if (updated.isNotEmpty) {
      await _folderRepository.updateFolders(folders: updated);
    }
  }
}
