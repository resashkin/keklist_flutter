import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:keklist/domain/repositories/weather/weather_repository.dart';
import 'package:keklist/domain/services/entities/weather_data.dart';
import 'package:keklist/domain/services/weather/weather_api_service.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';
import 'package:keklist/presentation/cubits/weather/weather_cubit.dart';
import 'package:keklist/presentation/screens/weather_detail/weather_detail_screen.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

final class WeatherPreviewCard extends StatefulWidget {
  final int dayIndex;
  final double latitude;
  final double longitude;

  const WeatherPreviewCard({
    super.key,
    required this.dayIndex,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<WeatherPreviewCard> createState() => _WeatherPreviewCardState();
}

final class _WeatherPreviewCardState extends State<WeatherPreviewCard> {
  late final WeatherCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = WeatherCubit(
      repository: context.read<WeatherRepository>(),
      apiService: WeatherApiService(),
    );
    _cubit.loadForDay(
      dayIndex: widget.dayIndex,
      latitude: widget.latitude,
      longitude: widget.longitude,
    );
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeatherCubit, WeatherState>(
      bloc: _cubit,
      builder: (context, state) {
        if (state is! WeatherLoaded) return const SizedBox.shrink();
        return _WeatherCardContent(
          data: state.data,
          onTap: () => _openDetail(context, state.data),
        );
      },
    );
  }

  void _openDetail(BuildContext context, WeatherData data) {
    Navigator.of(context).push(
      SwipeablePageRoute(builder: (_) => WeatherDetailScreen(data: data)),
    );
  }
}

final class _WeatherCardContent extends StatelessWidget {
  final WeatherData data;
  final VoidCallback onTap;

  const _WeatherCardContent({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
                    _weatherIcon(data),
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

IconData _weatherIcon(WeatherData data) {
  if (data.precipitation > 5.0) return Icons.thunderstorm;
  if (data.precipitation > 0.5) return Icons.grain;
  if (data.uvIndex > 4.0) return Icons.wb_sunny;
  return Icons.wb_cloudy;
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
