import 'dart:async';

import 'package:hive_ce/hive.dart';
import 'package:keklist/domain/repositories/emotion/emotion_folder_repository.dart';
import 'package:keklist/domain/repositories/emotion/object/emotion_folder_object.dart';
import 'package:keklist/domain/services/entities/emotion_folder.dart';
import 'package:rxdart/rxdart.dart';

final class EmotionFolderHiveRepository implements EmotionFolderRepository {
  final Box<EmotionFolderObject> _box;
  final BehaviorSubject<Iterable<EmotionFolder>> _subject = BehaviorSubject<Iterable<EmotionFolder>>();
  Iterable<EmotionFolderObject> get _objects => _box.values;

  EmotionFolderHiveRepository({required Box<EmotionFolderObject> box}) : _box = box {
    _subject.add(_objects.map((object) => object.toEmotionFolder()));
    _subject.addStream(
      _box
          .watch()
          .map((_) => _objects.map((object) => object.toEmotionFolder()))
          .debounceTime(const Duration(milliseconds: 100)),
    );
  }

  @override
  Iterable<EmotionFolder> get values => _subject.value;

  @override
  Stream<Iterable<EmotionFolder>> get stream => _subject.stream;

  @override
  FutureOr<Iterable<EmotionFolder>> obtainFolders() => _objects.map((object) => object.toEmotionFolder());

  @override
  FutureOr<EmotionFolder?> obtainFolder({required String id}) => _box.get(id)?.toEmotionFolder();

  @override
  FutureOr<void> createFolder({required EmotionFolder folder}) => _box.put(folder.id, folder.toObject());

  @override
  FutureOr<void> updateFolder({required EmotionFolder folder}) => _box.put(folder.id, folder.toObject());

  @override
  FutureOr<void> updateFolders({required Iterable<EmotionFolder> folders}) =>
      _box.putAll({for (final folder in folders) folder.id: folder.toObject()});

  @override
  FutureOr<void> deleteFolder({required String id}) => _box.delete(id);

  @override
  FutureOr<void> deleteFolders() => _box.clear();
}
