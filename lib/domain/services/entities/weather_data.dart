final class WeatherData {
  final int dayIndex;
  final double temperature;
  final double uvIndex;
  final double humidity;
  final double windSpeed;
  final double precipitation;
  final DateTime fetchedAt;

  // 24-element hourly lists for charts
  final List<double> hourlyTemperatures;
  final List<double> hourlyUvIndex;
  final List<double> hourlyHumidity;
  final List<double> hourlyWindSpeed;
  final List<double> hourlyPrecipitation;

  const WeatherData({
    required this.dayIndex,
    required this.temperature,
    required this.uvIndex,
    required this.humidity,
    required this.windSpeed,
    required this.precipitation,
    required this.fetchedAt,
    required this.hourlyTemperatures,
    required this.hourlyUvIndex,
    required this.hourlyHumidity,
    required this.hourlyWindSpeed,
    required this.hourlyPrecipitation,
  });
}
