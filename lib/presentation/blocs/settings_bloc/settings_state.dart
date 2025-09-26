part of 'settings_bloc.dart';

sealed class SettingsState {}

final class SettingsDataState extends SettingsState {
  final KeklistSettings settings;

  SettingsDataState({
    required this.settings,
  });
}

final class SettingsShowWhatsNew extends SettingsState {}

final class SettingsShowMessage extends SettingsState {
  final String title;
  final String message;

  SettingsShowMessage({
    required this.title,
    required this.message,
  });
}

final class SettingsLoadingState extends SettingsState {
  final bool isLoading;

  SettingsLoadingState(this.isLoading);
}
