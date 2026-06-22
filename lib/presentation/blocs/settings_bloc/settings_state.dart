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

final class SettingsExportSuccess extends SettingsState {
  final int mindsCount;
  final int audioFilesCount;
  final bool isEncrypted;

  SettingsExportSuccess({
    required this.mindsCount,
    required this.audioFilesCount,
    required this.isEncrypted,
  });
}

final class SettingsExportError extends SettingsState {
  final String message;

  SettingsExportError({required this.message});
}

final class SettingsImportSuccess extends SettingsState {
  final int mindsCount;
  final int audioFilesCount;

  SettingsImportSuccess({
    required this.mindsCount,
    required this.audioFilesCount,
  });
}

final class SettingsImportError extends SettingsState {
  final ImportError error;
  final String message;

  SettingsImportError({
    required this.error,
    required this.message,
  });
}
