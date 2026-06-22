part of 'settings_bloc.dart';

sealed class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => const [];
}

final class SettingsDataState extends SettingsState {
  final KeklistSettings settings;

  const SettingsDataState({
    required this.settings,
  });

  @override
  List<Object?> get props => [settings];
}

final class SettingsShowWhatsNew extends SettingsState {
  const SettingsShowWhatsNew();
}

final class SettingsShowMessage extends SettingsState {
  final String title;
  final String message;

  const SettingsShowMessage({
    required this.title,
    required this.message,
  });

  @override
  List<Object?> get props => [title, message];
}

final class SettingsLoadingState extends SettingsState {
  final bool isLoading;

  const SettingsLoadingState(this.isLoading);

  @override
  List<Object?> get props => [isLoading];
}

final class SettingsExportSuccess extends SettingsState {
  final int mindsCount;
  final int audioFilesCount;
  final bool isEncrypted;

  const SettingsExportSuccess({
    required this.mindsCount,
    required this.audioFilesCount,
    required this.isEncrypted,
  });

  @override
  List<Object?> get props => [mindsCount, audioFilesCount, isEncrypted];
}

final class SettingsExportError extends SettingsState {
  final String message;

  const SettingsExportError({required this.message});

  @override
  List<Object?> get props => [message];
}

final class SettingsImportSuccess extends SettingsState {
  final int mindsCount;
  final int audioFilesCount;

  const SettingsImportSuccess({
    required this.mindsCount,
    required this.audioFilesCount,
  });

  @override
  List<Object?> get props => [mindsCount, audioFilesCount];
}

final class SettingsImportError extends SettingsState {
  final ImportError error;
  final String message;

  const SettingsImportError({
    required this.error,
    required this.message,
  });

  @override
  List<Object?> get props => [error, message];
}
