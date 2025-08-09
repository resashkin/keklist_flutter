import 'package:hive_flutter/hive_flutter.dart';
import 'package:keklist/domain/repositories/debug_menu/debug_menu_repository.dart';
import 'package:keklist/presentation/core/helpers/enum_utils.dart';

part 'debug_menu_object.g.dart';

@HiveType(typeId: 4)
final class DebugMenuObject extends HiveObject {
  @HiveField(0, defaultValue: null)
  late String flagType;

  @HiveField(1, defaultValue: true)
  late bool value;

  DebugMenuData? toDebugMenuData() {
    final DebugMenuType? debugMenuType = EnumUtils.enumFromString(
      value: flagType,
      fromValues: DebugMenuType.values,
    );
    if (debugMenuType == null) return null;
    return DebugMenuData(
      type: debugMenuType,
      value: value,
    );
  }

  static DebugMenuObject fromDebugMenuData(DebugMenuData data) {
    return DebugMenuObject()
      ..flagType = data.type.name
      ..value = data.value;
  }
}
