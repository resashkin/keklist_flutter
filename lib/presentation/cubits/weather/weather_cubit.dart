import 'package:bloc/bloc.dart';
import 'package:keklist/domain/repositories/weather/weather_repository.dart';
import 'package:keklist/domain/services/entities/weather_data.dart';
import 'package:keklist/domain/services/weather/weather_api_service.dart';

sealed class WeatherState {}

class WeatherLoading extends WeatherState {}

class WeatherLoaded extends WeatherState {
  final WeatherData data;
  WeatherLoaded(this.data);
}

class WeatherError extends WeatherState {}

class WeatherDisabled extends WeatherState {}

final class WeatherCubit extends Cubit<WeatherState> {
  final WeatherRepository _repository;
  final WeatherApiService _apiService;

  WeatherCubit({
    required WeatherRepository repository,
    required WeatherApiService apiService,
  })  : _repository = repository,
        _apiService = apiService,
        super(WeatherDisabled());

  Future<void> loadForDay({
    required int dayIndex,
    required double latitude,
    required double longitude,
  }) async {
    emit(WeatherLoading());
    try {
      final data = await _repository.getWeatherForDay(
        dayIndex: dayIndex,
        latitude: latitude,
        longitude: longitude,
      );
      if (data != null) {
        final String? name = await _apiService.fetchLocationName(
          latitude: latitude,
          longitude: longitude,
        );
        emit(WeatherLoaded(data.copyWith(locationName: name)));
      } else {
        emit(WeatherError());
      }
    } catch (_) {
      emit(WeatherError());
    }
  }
}
