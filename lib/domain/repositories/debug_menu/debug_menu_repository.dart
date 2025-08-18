import 'dart:async';

abstract class DebugMenuRepository {
  List<DebugMenuData> get value;
  Stream<List<DebugMenuData>> get stream;
  FutureOr<void> update({DebugMenuType flagType, bool value});

  // Developer mode functionality
  bool get isDeveloperModeEnabled;
  Stream<bool> get developerModeStream;
  FutureOr<void> enableDeveloperMode();
}

final class DebugMenuData {
  final DebugMenuType type;
  final bool value;

  DebugMenuData({
    required this.type,
    required this.value,
  });
}

enum DebugMenuType {
  chatWithAI,
  translation,
  sensitiveContent,
  syncWithServer,
}
