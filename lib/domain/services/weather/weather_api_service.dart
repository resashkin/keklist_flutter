// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:keklist/domain/services/entities/weather_data.dart';
import 'package:keklist/presentation/core/helpers/date_utils.dart';

final class WeatherApiService {
  static const String _userAgent = 'keklist/4.5.0';

  /// Fetches weather data for a given day. Uses archive for past days (>5 days ago)
  /// and forecast for current/recent days, with MET Norway as fallback.
  Future<WeatherData?> fetchWeather({
    required int dayIndex,
    required double latitude,
    required double longitude,
  }) async {
    final DateTime dayDate = DateUtils.getDateFromDayIndex(dayIndex);
    final DateTime now = DateTime.now();
    final int daysAgo = now.difference(dayDate).inDays;
    final String dateStr = _formatDate(dayDate);

    if (daysAgo > 5) {
      return _fetchFromOpenMeteoArchive(
        dayIndex: dayIndex,
        latitude: latitude,
        longitude: longitude,
        dateStr: dateStr,
      );
    } else {
      final result = await _fetchFromOpenMeteoForecast(
        dayIndex: dayIndex,
        latitude: latitude,
        longitude: longitude,
        dateStr: dateStr,
      );
      if (result != null) return result;
      // Fallback to MET Norway
      return _fetchFromMetNorway(
        dayIndex: dayIndex,
        latitude: latitude,
        longitude: longitude,
      );
    }
  }

  Future<WeatherData?> _fetchFromOpenMeteoForecast({
    required int dayIndex,
    required double latitude,
    required double longitude,
    required String dateStr,
  }) async {
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$latitude&longitude=$longitude'
        '&hourly=temperature_2m,uv_index,relative_humidity_2m,wind_speed_10m,precipitation'
        '&start_date=$dateStr&end_date=$dateStr'
        '&timezone=auto',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return _parseOpenMeteoResponse(json, dayIndex);
    } catch (e) {
      print('[WeatherApiService] Open-Meteo forecast error: $e');
      return null;
    }
  }

  Future<WeatherData?> _fetchFromOpenMeteoArchive({
    required int dayIndex,
    required double latitude,
    required double longitude,
    required String dateStr,
  }) async {
    try {
      final uri = Uri.parse(
        'https://archive-api.open-meteo.com/v1/archive'
        '?latitude=$latitude&longitude=$longitude'
        '&hourly=temperature_2m,uv_index,relative_humidity_2m,wind_speed_10m,precipitation'
        '&start_date=$dateStr&end_date=$dateStr'
        '&timezone=auto',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return _parseOpenMeteoResponse(json, dayIndex);
    } catch (e) {
      print('[WeatherApiService] Open-Meteo archive error: $e');
      return null;
    }
  }

  Future<WeatherData?> _fetchFromMetNorway({
    required int dayIndex,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final uri = Uri.parse(
        'https://api.met.no/weatherapi/locationforecast/2.0/compact?lat=$latitude&lon=$longitude',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': _userAgent},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return _parseMetNorwayResponse(json, dayIndex);
    } catch (e) {
      print('[WeatherApiService] MET Norway error: $e');
      return null;
    }
  }

  WeatherData? _parseOpenMeteoResponse(Map<String, dynamic> json, int dayIndex) {
    try {
      final hourly = json['hourly'] as Map<String, dynamic>;
      final temps = _toDoubleList(hourly['temperature_2m']);
      final uvs = _toDoubleList(hourly['uv_index']);
      final humidities = _toDoubleList(hourly['relative_humidity_2m']);
      final winds = _toDoubleList(hourly['wind_speed_10m']);
      final precips = _toDoubleList(hourly['precipitation']);

      final int noonIndex = 12.clamp(0, temps.length - 1);

      return WeatherData(
        dayIndex: dayIndex,
        temperature: temps.isNotEmpty ? temps[noonIndex] : 0.0,
        uvIndex: uvs.isNotEmpty ? uvs[noonIndex] : 0.0,
        humidity: humidities.isNotEmpty ? humidities[noonIndex] : 0.0,
        windSpeed: winds.isNotEmpty ? winds[noonIndex] : 0.0,
        precipitation: precips.isNotEmpty ? precips.reduce((a, b) => a + b) : 0.0,
        fetchedAt: DateTime.now(),
        hourlyTemperatures: _pad24(temps),
        hourlyUvIndex: _pad24(uvs),
        hourlyHumidity: _pad24(humidities),
        hourlyWindSpeed: _pad24(winds),
        hourlyPrecipitation: _pad24(precips),
      );
    } catch (e) {
      print('[WeatherApiService] Parse Open-Meteo error: $e');
      return null;
    }
  }

  WeatherData? _parseMetNorwayResponse(Map<String, dynamic> json, int dayIndex) {
    try {
      final properties = json['properties'] as Map<String, dynamic>;
      final timeseries = (properties['timeseries'] as List).cast<Map<String, dynamic>>();

      final List<double> temps = [];
      final List<double> winds = [];
      final List<double> humidities = [];

      for (final entry in timeseries.take(24)) {
        final instant = entry['data']['instant']['details'] as Map<String, dynamic>;
        temps.add((instant['air_temperature'] as num).toDouble());
        winds.add((instant['wind_speed'] as num).toDouble());
        humidities.add((instant['relative_humidity'] as num).toDouble());
      }

      final int noonIndex = 12.clamp(0, temps.length - 1);

      return WeatherData(
        dayIndex: dayIndex,
        temperature: temps.isNotEmpty ? temps[noonIndex] : 0.0,
        uvIndex: 0.0,
        humidity: humidities.isNotEmpty ? humidities[noonIndex] : 0.0,
        windSpeed: winds.isNotEmpty ? winds[noonIndex] : 0.0,
        precipitation: 0.0,
        fetchedAt: DateTime.now(),
        hourlyTemperatures: _pad24(temps),
        hourlyUvIndex: List.filled(24, 0.0),
        hourlyHumidity: _pad24(humidities),
        hourlyWindSpeed: _pad24(winds),
        hourlyPrecipitation: List.filled(24, 0.0),
      );
    } catch (e) {
      print('[WeatherApiService] Parse MET Norway error: $e');
      return null;
    }
  }

  List<double> _toDoubleList(dynamic raw) {
    if (raw == null) return [];
    return (raw as List).map((e) => e == null ? 0.0 : (e as num).toDouble()).toList();
  }

  List<double> _pad24(List<double> list) {
    if (list.length >= 24) return list.take(24).toList();
    return [...list, ...List.filled(24 - list.length, 0.0)];
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
