// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_cache_object.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WeatherCacheObjectAdapter extends TypeAdapter<WeatherCacheObject> {
  @override
  final typeId = 2;

  @override
  WeatherCacheObject read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WeatherCacheObject()
      ..dayIndex = (fields[0] as num).toInt()
      ..temperature = (fields[1] as num).toDouble()
      ..uvIndex = (fields[2] as num).toDouble()
      ..humidity = (fields[3] as num).toDouble()
      ..windSpeed = (fields[4] as num).toDouble()
      ..precipitation = (fields[5] as num).toDouble()
      ..fetchedAt = fields[6] as DateTime
      ..hourlyTemperatures = (fields[7] as List).cast<double>()
      ..hourlyUvIndex = (fields[8] as List).cast<double>()
      ..hourlyHumidity = (fields[9] as List).cast<double>()
      ..hourlyWindSpeed = (fields[10] as List).cast<double>()
      ..hourlyPrecipitation = (fields[11] as List).cast<double>();
  }

  @override
  void write(BinaryWriter writer, WeatherCacheObject obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.dayIndex)
      ..writeByte(1)
      ..write(obj.temperature)
      ..writeByte(2)
      ..write(obj.uvIndex)
      ..writeByte(3)
      ..write(obj.humidity)
      ..writeByte(4)
      ..write(obj.windSpeed)
      ..writeByte(5)
      ..write(obj.precipitation)
      ..writeByte(6)
      ..write(obj.fetchedAt)
      ..writeByte(7)
      ..write(obj.hourlyTemperatures)
      ..writeByte(8)
      ..write(obj.hourlyUvIndex)
      ..writeByte(9)
      ..write(obj.hourlyHumidity)
      ..writeByte(10)
      ..write(obj.hourlyWindSpeed)
      ..writeByte(11)
      ..write(obj.hourlyPrecipitation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeatherCacheObjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
