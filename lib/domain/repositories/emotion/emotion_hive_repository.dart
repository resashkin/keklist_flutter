import 'dart:async';

import 'package:hive_ce/hive.dart';
import 'package:keklist/domain/repositories/emotion/emotion_repository.dart';
import 'package:keklist/domain/repositories/emotion/object/emotion_object.dart';
import 'package:keklist/domain/services/entities/emotion.dart';
import 'package:rxdart/rxdart.dart';

final class EmotionHiveRepository implements EmotionRepository {
  final Box<EmotionObject> _box;
  final BehaviorSubject<Iterable<Emotion>> _subject = BehaviorSubject<Iterable<Emotion>>();
  Iterable<EmotionObject> get _objects => _box.values;

  EmotionHiveRepository({required Box<EmotionObject> box}) : _box = box {
    _subject.add(_objects.map((object) => object.toEmotion()));
    _subject.addStream(
      _box
          .watch()
          .map((_) => _objects.map((object) => object.toEmotion()))
          .debounceTime(const Duration(milliseconds: 100)),
    );
  }

  @override
  Iterable<Emotion> get values => _subject.value;

  @override
  Stream<Iterable<Emotion>> get stream => _subject.stream;

  @override
  FutureOr<Iterable<Emotion>> obtainEmotions() => _objects.map((object) => object.toEmotion());

  @override
  FutureOr<Emotion?> obtainEmotion({required String id}) => _box.get(id)?.toEmotion();

  @override
  FutureOr<void> createEmotion({required Emotion emotion}) => _box.put(emotion.id, emotion.toObject());

  @override
  FutureOr<void> createEmotions({required Iterable<Emotion> emotions}) =>
      _box.putAll({for (final emotion in emotions) emotion.id: emotion.toObject()});

  @override
  FutureOr<void> updateEmotion({required Emotion emotion}) => _box.put(emotion.id, emotion.toObject());

  @override
  FutureOr<void> updateEmotions({required Iterable<Emotion> emotions}) =>
      _box.putAll({for (final emotion in emotions) emotion.id: emotion.toObject()});

  @override
  FutureOr<void> deleteEmotion({required String id}) => _box.delete(id);

  @override
  FutureOr<void> deleteEmotions() => _box.clear();
}
