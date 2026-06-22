part of 'settings_bloc.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => const [];
}

final class SettingsGet extends SettingsEvent {
  const SettingsGet();
}

final class SettingsExport extends SettingsEvent {
  final SettingsExportType type;
  final String? password;
  final SettingsExportAction action;

  const SettingsExport({
    required this.type,
    this.password,
    this.action = SettingsExportAction.share,
  });

  @override
  List<Object?> get props => [type, password, action];
}

final class SettingsImport extends SettingsEvent {
  final File file;
  final String? password;

  const SettingsImport({required this.file, this.password});

  @override
  List<Object?> get props => [file.path, password];
}

enum SettingsExportType { csv, zip }

enum SettingsExportAction { saveToFiles, share }

@Deprecated('Use SettingsImport with file parameter instead')
enum SettingsImportType { csv }

final class SettingsExportAllMindsToCSV extends SettingsEvent {
  const SettingsExportAllMindsToCSV();
}

final class SettingsChangeMindContentVisibility extends SettingsEvent {
  final bool isVisible;

  const SettingsChangeMindContentVisibility({required this.isVisible});

  @override
  List<Object?> get props => [isVisible];
}

final class SettingsWhatsNewShown extends SettingsEvent {
  const SettingsWhatsNewShown();
}

final class SettingsUploadMindsFromCacheToServer extends SettingsEvent {
  const SettingsUploadMindsFromCacheToServer();
}

final class SettingGetWhatsNew extends SettingsEvent {
  const SettingGetWhatsNew();
}

final class SettingsChangeThemePreference extends SettingsEvent {
  final KeklistThemeMode themePreference;

  const SettingsChangeThemePreference({required this.themePreference});

  @override
  List<Object?> get props => [themePreference];
}

final class SettingsGetMindCandidatesToUpload extends SettingsEvent {
  const SettingsGetMindCandidatesToUpload();
}

final class SettingsUploadMindCandidates extends SettingsEvent {
  const SettingsUploadMindCandidates();
}

final class SettingsUpdateShouldShowTitlesMode extends SettingsEvent {
  final bool value;

  const SettingsUpdateShouldShowTitlesMode({required this.value});

  @override
  List<Object?> get props => [value];
}

final class SettingsChangeLanguage extends SettingsEvent {
  final SupportedLanguage language;

  const SettingsChangeLanguage({required this.language});

  @override
  List<Object?> get props => [language];
}

final class SettingsEnableDebugMenu extends SettingsEvent {
  const SettingsEnableDebugMenu();
}

final class SettingsTogglePhotoVideoSource extends SettingsEvent {
  final bool isEnabled;
  const SettingsTogglePhotoVideoSource({required this.isEnabled});

  @override
  List<Object?> get props => [isEnabled];
}

final class SettingsToggleWeatherSource extends SettingsEvent {
  final bool isEnabled;
  const SettingsToggleWeatherSource({required this.isEnabled});

  @override
  List<Object?> get props => [isEnabled];
}

final class SettingsUpdateWeatherLocation extends SettingsEvent {
  final double latitude;
  final double longitude;
  const SettingsUpdateWeatherLocation({required this.latitude, required this.longitude});

  @override
  List<Object?> get props => [latitude, longitude];
}

final class SettingsUpdateMediaFolderSource extends SettingsEvent {
  final bool? isEnabled;
  final String? folderPath;
  final bool? isRecursive;
  const SettingsUpdateMediaFolderSource({this.isEnabled, this.folderPath, this.isRecursive});

  @override
  List<Object?> get props => [isEnabled, folderPath, isRecursive];
}
