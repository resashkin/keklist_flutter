// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_object.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsObjectAdapter extends TypeAdapter<SettingsObject> {
  @override
  final int typeId = 0;

  @override
  SettingsObject read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsObject()
      ..isMindContentVisible = fields[0] == null ? true : fields[0] as bool
      ..previousAppVersion = fields[1] as String?
      ..isDarkMode = fields[3] == null ? true : fields[3] as bool
      ..shouldShowTitles = fields[5] == null ? true : fields[5] as bool
      ..userName = fields[6] as String?
      ..language = fields[7] == null ? 'en' : fields[7] as String
      ..dataSchemaVersion = fields[8] == null ? 0 : fields[8] as int
      ..hasSeenLazyOnboarding = fields[9] == null ? false : fields[9] as bool
      ..isDebugMenuVisible = fields[10] == null ? false : fields[10] as bool
      ..isPhotoVideoSourceEnabled =
          fields[11] == null ? false : fields[11] as bool;
  }

  @override
  void write(BinaryWriter writer, SettingsObject obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.isMindContentVisible)
      ..writeByte(1)
      ..write(obj.previousAppVersion)
      ..writeByte(3)
      ..write(obj.isDarkMode)
      ..writeByte(5)
      ..write(obj.shouldShowTitles)
      ..writeByte(6)
      ..write(obj.userName)
      ..writeByte(7)
      ..write(obj.language)
      ..writeByte(8)
      ..write(obj.dataSchemaVersion)
      ..writeByte(9)
      ..write(obj.hasSeenLazyOnboarding)
      ..writeByte(10)
      ..write(obj.isDebugMenuVisible)
      ..writeByte(11)
      ..write(obj.isPhotoVideoSourceEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsObjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
