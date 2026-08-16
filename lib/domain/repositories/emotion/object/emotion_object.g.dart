// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emotion_object.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmotionObjectAdapter extends TypeAdapter<EmotionObject> {
  @override
  final typeId = 3;

  @override
  EmotionObject read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmotionObject()
      ..id = fields[0] as String
      ..title = fields[1] as String
      ..emoji = fields[2] as String
      ..isArchived = fields[4] == null ? false : fields[4] as bool
      ..orderIndex = fields[5] == null ? 0 : (fields[5] as num).toInt()
      ..creationDate = fields[6] as DateTime
      ..parentId = fields[7] as String?;
  }

  @override
  void write(BinaryWriter writer, EmotionObject obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.emoji)
      ..writeByte(4)
      ..write(obj.isArchived)
      ..writeByte(5)
      ..write(obj.orderIndex)
      ..writeByte(6)
      ..write(obj.creationDate)
      ..writeByte(7)
      ..write(obj.parentId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmotionObjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
