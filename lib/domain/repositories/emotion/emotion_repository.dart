import 'dart:async';

import 'package:keklist/domain/services/entities/emotion.dart';

abstract class EmotionRepository {
  Iterable<Emotion> get values;
  Stream<Iterable<Emotion>> get stream;
  FutureOr<Iterable<Emotion>> obtainEmotions();
  FutureOr<Emotion?> obtainEmotion({required String id});
  FutureOr<void> createEmotion({required Emotion emotion});
  FutureOr<void> createEmotions({required Iterable<Emotion> emotions});
  FutureOr<void> updateEmotion({required Emotion emotion});
  FutureOr<void> updateEmotions({required Iterable<Emotion> emotions});
  FutureOr<void> deleteEmotion({required String id});
  FutureOr<void> deleteEmotions();
}
