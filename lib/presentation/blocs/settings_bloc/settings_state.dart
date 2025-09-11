part of 'settings_bloc.dart';

sealed class SettingsState {}

final class SettingsDataState extends SettingsState {
  final KeklistSettings settings;

  SettingsDataState({
    required this.settings,
  });
}

final class SettingsNeedToShowWhatsNew extends SettingsState {}

final class SettingsLoadingState extends SettingsState {
  final bool isLoading;

  SettingsLoadingState(this.isLoading);
}
