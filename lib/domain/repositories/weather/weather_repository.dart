import 'package:keklist/domain/services/entities/weather_data.dart';

abstract class WeatherRepository {
  Future<WeatherData?> getWeatherForDay({
    required int dayIndex,
    required double latitude,
    required double longitude,
  });

  Future<void> clearCache();
}
