import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:keklist/domain/repositories/weather/weather_repository.dart';
import 'package:keklist/domain/services/entities/weather_data.dart';
import 'package:keklist/domain/services/weather/weather_api_service.dart';

sealed class WeatherState extends Equatable {
  const WeatherState();

  @override
  List<Object?> get props => const [];
}

class WeatherLoading extends WeatherState {
  const WeatherLoading();
}

class WeatherLoaded extends WeatherState {
  final WeatherData data;
  const WeatherLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class WeatherError extends WeatherState {
  const WeatherError();
}

class WeatherDisabled extends WeatherState {
  const WeatherDisabled();
}

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
