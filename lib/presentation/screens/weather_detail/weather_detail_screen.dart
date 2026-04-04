import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart' hide DateUtils;
import 'package:keklist/domain/constants.dart';
import 'package:keklist/domain/services/entities/weather_data.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';
import 'package:keklist/presentation/core/helpers/date_utils.dart';

final class WeatherDetailScreen extends StatelessWidget {
  final WeatherData data;

  const WeatherDetailScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final DateTime date = DateUtils.getDateFromDayIndex(data.dayIndex);
    final Locale locale = Localizations.localeOf(context);
    final String title = DateFormatters.formatFullDate(date, locale);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (data.locationName != null) ...[
              Text(
                data.locationName!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12.0),
            ],
            _TemperatureChart(hourlyTemperatures: data.hourlyTemperatures),
            const SizedBox(height: 24.0),
            Text(
              context.l10n.weatherMoodImpact,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12.0),
            _ParameterTile(
              icon: Icons.thermostat,
              label: context.l10n.weatherTemperature,
              value: '${data.temperature.toStringAsFixed(1)}°C',
            ),
            _ParameterTile(
              icon: Icons.wb_sunny,
              label: context.l10n.weatherUvIndex,
              value: data.uvIndex.toStringAsFixed(1),
            ),
            _ParameterTile(
              icon: Icons.water_drop,
              label: context.l10n.weatherHumidity,
              value: '${data.humidity.toStringAsFixed(0)}%',
            ),
            _ParameterTile(
              icon: Icons.air,
              label: context.l10n.weatherWindSpeed,
              value: '${data.windSpeed.toStringAsFixed(1)} km/h',
            ),
            _ParameterTile(
              icon: Icons.grain,
              label: context.l10n.weatherPrecipitation,
              value: '${data.precipitation.toStringAsFixed(1)} mm',
            ),
          ],
        ),
      ),
    );
  }
}

final class _TemperatureChart extends StatelessWidget {
  final List<double> hourlyTemperatures;

  const _TemperatureChart({required this.hourlyTemperatures});

  @override
  Widget build(BuildContext context) {
    if (hourlyTemperatures.isEmpty) return const SizedBox.shrink();

    final spots = hourlyTemperatures
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    final double minY = hourlyTemperatures.reduce((a, b) => a < b ? a : b) - 2;
    final double maxY = hourlyTemperatures.reduce((a, b) => a > b ? a : b) + 2;

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toStringAsFixed(0)}°',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 6,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}h',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 2,
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              ),
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

final class _ParameterTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ParameterTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20.0, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
