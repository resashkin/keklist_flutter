import 'dart:async';

import 'package:keklist/domain/services/entities/mind.dart';

abstract class MindRepository {
  Iterable<Mind> get values;
  Stream<Iterable<Mind>> get stream;
  FutureOr<Iterable<Mind>> obtainMinds();
  FutureOr<Mind> createMind({required Mind mind});
  FutureOr<void> createMinds({required Iterable<Mind> minds});
  FutureOr<Mind?> obtainMind({required String mindId});
  FutureOr<Iterable<Mind>> obtainMindsWhere(bool Function(Mind) where);
  FutureOr<void> updateMind({required Mind mind});
  FutureOr<void> updateMinds({required Iterable<Mind> minds});
  FutureOr<void> deleteMind({required String mindId});
  FutureOr<void> deleteMinds();
  FutureOr<void> deleteMindsWhere(bool Function(Mind) where);  
}
