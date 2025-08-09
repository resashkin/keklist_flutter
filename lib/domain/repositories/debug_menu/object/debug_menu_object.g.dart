// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debug_menu_object.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DebugMenuObjectAdapter extends TypeAdapter<DebugMenuObject> {
  @override
  final int typeId = 4;

  @override
  DebugMenuObject read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DebugMenuObject()
      ..flagType = fields[0] as String
      ..value = fields[1] == null ? true : fields[1] as bool;
  }

  @override
  void write(BinaryWriter writer, DebugMenuObject obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.flagType)
      ..writeByte(1)
      ..write(obj.value);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DebugMenuObjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
