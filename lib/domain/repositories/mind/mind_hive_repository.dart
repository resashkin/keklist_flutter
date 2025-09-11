import 'dart:async';

import 'package:hive/hive.dart';
import 'package:keklist/domain/repositories/mind/object/mind_object.dart';
import 'package:keklist/domain/services/entities/mind.dart';
import 'package:keklist/domain/repositories/mind/mind_repository.dart';
import 'package:rxdart/rxdart.dart';

final class MindHiveRepository implements MindRepository {
  final Box<MindObject> _mindHiveBox;
  final BehaviorSubject<Iterable<Mind>> _mindsBehaviorSubject = BehaviorSubject<Iterable<Mind>>();
  Iterable<MindObject> get _mindObjects => _mindHiveBox.values;

  MindHiveRepository({required Box<MindObject> box}) : _mindHiveBox = box {
    _mindsBehaviorSubject.add(_mindObjects.map((mindObject) => mindObject.toMind()));
    _mindsBehaviorSubject.addStream(
      _mindHiveBox
          .watch()
          .map((_) => _mindObjects.map((mindObject) => mindObject.toMind()))
          .debounceTime(const Duration(milliseconds: 100)),
    );
  }

  @override
  Iterable<Mind> get values => _mindsBehaviorSubject.value;

  @override
  Stream<Iterable<Mind>> get stream => _mindsBehaviorSubject.stream;

  @override
  FutureOr<Mind> createMind({required Mind mind}) async {
    final MindObject object = mind.toObject();
    await _mindHiveBox.put(mind.id, object);
    return mind;
  }

  @override
  FutureOr<void> createMinds({required Iterable<Mind> minds}) {
    final Iterable<MindObject> objects = minds.map((mind) => mind.toObject());
    _mindHiveBox.putAll({for (var object in objects) object.id: object});
  }

  @override
  FutureOr<void> deleteMind({required String mindId}) {
    final MindObject? object = _mindHiveBox.get(mindId);
    object?.delete();
  }

  @override
  FutureOr<Mind?> obtainMind({required String mindId}) {
    final MindObject? object = _mindHiveBox.get(mindId);
    return object?.toMind();
  }

  @override
  FutureOr<Iterable<Mind>> obtainMinds() {
    return _mindObjects.map((mindObject) => mindObject.toMind());
  }

  @override
  FutureOr<void> updateMind({required Mind mind}) {
    final MindObject object = mind.toObject();
    return _mindHiveBox.put(mind.id, object);
  }

  @override
  FutureOr<void> updateMinds({required Iterable<Mind> minds}) async {
    final mindEntries = {for (final mind in minds) mind.id: mind.toObject()};
    await _mindHiveBox.putAll(mindEntries);
  }

  @override
  FutureOr<Iterable<Mind>> obtainMindsWhere(bool Function(Mind) where) {
    return _mindObjects.map((mindObject) => mindObject.toMind()).where(where);
  }

  @override
  FutureOr<void> deleteMindsWhere(bool Function(Mind) where) async {
    final Iterable<String> mindIds =
        _mindObjects.map((mindObject) => mindObject.toMind()).where(where).map((mind) => mind.id);
    await _mindHiveBox.deleteAll(mindIds);
  }

  @override
  FutureOr<void> deleteMinds() async {
    await _mindHiveBox.clear();
  }
}
