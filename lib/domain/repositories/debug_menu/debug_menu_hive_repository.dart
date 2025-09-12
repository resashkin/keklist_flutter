import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:keklist/domain/repositories/debug_menu/debug_menu_repository.dart';
import 'package:keklist/domain/repositories/debug_menu/object/debug_menu_object.dart';
import 'package:rxdart/rxdart.dart';

final class DebugMenuHiveRepository implements DebugMenuRepository {
  final Box<DebugMenuObject> _hiveBox;
  final BehaviorSubject<List<DebugMenuData>> _behaviorSubject = BehaviorSubject<List<DebugMenuData>>();
  final BehaviorSubject<bool> _developerModeBehaviorSubject = BehaviorSubject<bool>();

  static const String _developerModeKey = 'developer_mode_enabled';
  Iterable<DebugMenuObject> get _debugMenuObjects => _hiveBox.values;

  DebugMenuHiveRepository({required Box<DebugMenuObject> box}) : _hiveBox = box {
    _initializeDefaultValues();
    _behaviorSubject.add(_getCurrentDebugMenuItems());
    _developerModeBehaviorSubject.add(_isDeveloperModeEnabled());
    _behaviorSubject.addStream(
      _hiveBox.watch().map((_) => _getCurrentDebugMenuItems()).debounceTime(const Duration(milliseconds: 10)),
    );
    _developerModeBehaviorSubject.addStream(
      _hiveBox.watch().map((_) => _isDeveloperModeEnabled()).debounceTime(const Duration(milliseconds: 10)),
    );
  }

  void _initializeDefaultValues() {
    // Initialize default values for all debug menu items if they don't exist
    for (final DebugMenuType flagType in DebugMenuType.values) {
      final String key = flagType.name;
      if (!_hiveBox.containsKey(key)) {
        final defaultObject = DebugMenuObject()
          ..flagType = flagType.name
          ..value = _getDefaultValueForFlag(flagType);
        _hiveBox.put(key, defaultObject);
      }
    }
  }

  bool _getDefaultValueForFlag(DebugMenuType flagType) => switch (flagType) {
        DebugMenuType.chatWithAI => true,
        DebugMenuType.translation => true,
        DebugMenuType.sensitiveContent => false,
      };

  List<DebugMenuData> _getCurrentDebugMenuItems() =>
      _debugMenuObjects.map((obj) => obj.toDebugMenuData()).whereType<DebugMenuData>().toList();

  @override
  List<DebugMenuData> get value => _behaviorSubject.value;

  @override
  Stream<List<DebugMenuData>> get stream => _behaviorSubject.stream;

  @override
  FutureOr<void> update({DebugMenuType? flagType, bool? value}) async {
    if (flagType == null || value == null) return;
    final String key = flagType.name;
    final DebugMenuObject? existingObject = _hiveBox.get(key);

    if (existingObject != null) {
      existingObject.value = value;
      await existingObject.save();
    } else {
      final newObject = DebugMenuObject()
        ..flagType = flagType.name
        ..value = value;
      await _hiveBox.put(key, newObject);
    }
  }

  bool _isDeveloperModeEnabled() {
    final DebugMenuObject? developerModeObject = _hiveBox.get(_developerModeKey);
    return developerModeObject?.value ?? false;
  }

  @override
  bool get isDeveloperModeEnabled => _developerModeBehaviorSubject.value;

  @override
  Stream<bool> get developerModeStream => _developerModeBehaviorSubject.stream;

  @override
  FutureOr<void> enableDeveloperMode() async {
    final DebugMenuObject? existingObject = _hiveBox.get(_developerModeKey);

    if (existingObject != null) {
      existingObject.value = true;
      await existingObject.save();
    } else {
      final newObject = DebugMenuObject()
        ..flagType = _developerModeKey
        ..value = true;
      await _hiveBox.put(_developerModeKey, newObject);
    }
  }
}
