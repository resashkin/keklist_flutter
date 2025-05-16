import 'package:collection/collection.dart';

final class EnumUtils {
  static T? enumFromString<T extends Enum>({
    required String? value,
    required Iterable<T> fromValues,
  }) =>
      fromValues.firstWhereOrNull((type) => stringFromEnum(type) == value);

  static String stringFromEnum<T>(T value) => value.toString().split(".").last;
}
