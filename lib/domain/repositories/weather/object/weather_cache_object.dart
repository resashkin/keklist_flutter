import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:keklist/domain/services/entities/weather_data.dart';

part 'weather_cache_object.g.dart';

@HiveType(typeId: 2)
final class WeatherCacheObject extends HiveObject {
  @HiveField(0)
  late int dayIndex;

  @HiveField(1)
  late double temperature;

  @HiveField(2)
  late double uvIndex;

  @HiveField(3)
  late double humidity;

  @HiveField(4)
  late double windSpeed;

  @HiveField(5)
  late double precipitation;

  @HiveField(6)
  late DateTime fetchedAt;

  @HiveField(7)
  late List<double> hourlyTemperatures;

  @HiveField(8)
  late List<double> hourlyUvIndex;

  @HiveField(9)
  late List<double> hourlyHumidity;

  @HiveField(10)
  late List<double> hourlyWindSpeed;

  @HiveField(11)
  late List<double> hourlyPrecipitation;

  WeatherCacheObject();

  WeatherData toWeatherData() => WeatherData(
        dayIndex: dayIndex,
        temperature: temperature,
        uvIndex: uvIndex,
        humidity: humidity,
        windSpeed: windSpeed,
        precipitation: precipitation,
        fetchedAt: fetchedAt,
        hourlyTemperatures: hourlyTemperatures,
        hourlyUvIndex: hourlyUvIndex,
        hourlyHumidity: hourlyHumidity,
        hourlyWindSpeed: hourlyWindSpeed,
        hourlyPrecipitation: hourlyPrecipitation,
      );

  static WeatherCacheObject fromWeatherData(WeatherData data) => WeatherCacheObject()
    ..dayIndex = data.dayIndex
    ..temperature = data.temperature
    ..uvIndex = data.uvIndex
    ..humidity = data.humidity
    ..windSpeed = data.windSpeed
    ..precipitation = data.precipitation
    ..fetchedAt = data.fetchedAt
    ..hourlyTemperatures = data.hourlyTemperatures
    ..hourlyUvIndex = data.hourlyUvIndex
    ..hourlyHumidity = data.hourlyHumidity
    ..hourlyWindSpeed = data.hourlyWindSpeed
    ..hourlyPrecipitation = data.hourlyPrecipitation;
}
