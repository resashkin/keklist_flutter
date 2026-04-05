import 'package:hive_ce/hive.dart';
import 'package:keklist/domain/repositories/weather/object/weather_cache_object.dart';
import 'package:keklist/domain/repositories/weather/weather_repository.dart';
import 'package:keklist/domain/services/entities/weather_data.dart';
import 'package:keklist/domain/services/weather/weather_api_service.dart';
import 'package:keklist/presentation/core/helpers/date_utils.dart';

final class WeatherHiveRepository implements WeatherRepository {
  final Box<WeatherCacheObject> _box;
  final WeatherApiService _apiService;

  static const Duration _currentDayCacheExpiry = Duration(hours: 1);

  WeatherHiveRepository({
    required Box<WeatherCacheObject> box,
    required WeatherApiService apiService,
  })  : _box = box,
        _apiService = apiService;

  @override
  Future<WeatherData?> getWeatherForDay({
    required int dayIndex,
    required double latitude,
    required double longitude,
  }) async {
    final String key = dayIndex.toString();
    final WeatherCacheObject? cached = _box.get(key);

    if (cached != null) {
      final DateTime now = DateTime.now();
      final bool isPastDay = _isPastDay(dayIndex);

      if (isPastDay) {
        // Past days are cached indefinitely
        return cached.toWeatherData();
      } else {
        // Current / future days: expire after 60 min
        if (now.difference(cached.fetchedAt) < _currentDayCacheExpiry) {
          return cached.toWeatherData();
        }
      }
    }

    // Cache miss or expired — fetch fresh data
    final WeatherData? fresh = await _apiService.fetchWeather(
      dayIndex: dayIndex,
      latitude: latitude,
      longitude: longitude,
    );
    if (fresh != null) {
      await _box.put(key, WeatherCacheObject.fromWeatherData(fresh));
    }
    return fresh;
  }

  @override
  Future<void> clearCache() async {
    await _box.clear();
  }

  bool _isPastDay(int dayIndex) {
    final DateTime today = DateTime.now();
    final int todayIndex = DateUtils.getDayIndex(from: today);
    return dayIndex < todayIndex - 5;
  }
}
