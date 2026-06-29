// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emotion_folder_object.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmotionFolderObjectAdapter extends TypeAdapter<EmotionFolderObject> {
  @override
  final typeId = 5;

  @override
  EmotionFolderObject read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmotionFolderObject()
      ..id = fields[0] as String
      ..title = fields[1] as String
      ..orderIndex = fields[2] == null ? 0 : (fields[2] as num).toInt()
      ..creationDate = fields[3] as DateTime;
  }

  @override
  void write(BinaryWriter writer, EmotionFolderObject obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.orderIndex)
      ..writeByte(3)
      ..write(obj.creationDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmotionFolderObjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
