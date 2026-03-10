import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:keklist/domain/services/entities/weather_data.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';
import 'package:keklist/presentation/screens/weather_detail/weather_detail_screen.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

final class WeatherDayTileWidget extends StatelessWidget {
  final WeatherData data;

  const WeatherDayTileWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          SwipeablePageRoute(builder: (_) => WeatherDetailScreen(data: data)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    context.l10n.sourcesWeather,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 16.0),
                ],
              ),
              const Gap(8.0),
              Row(
                children: [
                  Icon(
                    Icons.wb_cloudy,
                    size: 24.0,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const Gap(8.0),
                  Text(
                    '${data.temperature.round()}°C',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  _ParamChip(icon: Icons.wb_sunny, value: data.uvIndex.round().toString()),
                  const Gap(4.0),
                  _ParamChip(icon: Icons.water_drop, value: '${data.humidity.toStringAsFixed(0)}%'),
                  const Gap(4.0),
                  _ParamChip(icon: Icons.air, value: data.windSpeed.toStringAsFixed(0)),
                  const Gap(4.0),
                  _ParamChip(icon: Icons.grain, value: '${data.precipitation.round()}mm'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _ParamChip extends StatelessWidget {
  final IconData icon;
  final String value;

  const _ParamChip({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.0, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const Gap(2.0),
          Text(value, style: const TextStyle(fontSize: 10.0)),
        ],
      ),
    );
  }
}
