import 'dart:async';

import 'package:keklist/domain/services/entities/emotion_folder.dart';

abstract class EmotionFolderRepository {
  Iterable<EmotionFolder> get values;
  Stream<Iterable<EmotionFolder>> get stream;
  FutureOr<Iterable<EmotionFolder>> obtainFolders();
  FutureOr<EmotionFolder?> obtainFolder({required String id});
  FutureOr<void> createFolder({required EmotionFolder folder});
  FutureOr<void> updateFolder({required EmotionFolder folder});
  FutureOr<void> updateFolders({required Iterable<EmotionFolder> folders});
  FutureOr<void> deleteFolder({required String id});
  FutureOr<void> deleteFolders();
}
