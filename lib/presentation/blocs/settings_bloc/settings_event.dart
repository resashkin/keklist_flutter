part of 'settings_bloc.dart';

sealed class SettingsEvent {
  const SettingsEvent();
}

final class SettingsGet extends SettingsEvent {}

final class SettingsExport extends SettingsEvent {
  final SettingsExportType type;
  final String? password;
  final SettingsExportAction action;

  SettingsExport({
    required this.type,
    this.password,
    this.action = SettingsExportAction.share,
  });
}

final class SettingsImport extends SettingsEvent {
  final File file;
  final String? password;

  SettingsImport({required this.file, this.password});
}

enum SettingsExportType { csv, zip }

enum SettingsExportAction { saveToFiles, share }

@Deprecated('Use SettingsImport with file parameter instead')
enum SettingsImportType { csv }

final class SettingsExportAllMindsToCSV extends SettingsEvent {}

final class SettingsChangeMindContentVisibility extends SettingsEvent {
  final bool isVisible;

  const SettingsChangeMindContentVisibility({required this.isVisible});
}

final class SettingsWhatsNewShown extends SettingsEvent {}

final class SettingsUploadMindsFromCacheToServer extends SettingsEvent {}

final class SettingGetWhatsNew extends SettingsEvent {}

final class SettingsChangeIsDarkMode extends SettingsEvent {
  final bool isDarkMode;

  const SettingsChangeIsDarkMode({required this.isDarkMode});
}

final class SettingsGetMindCandidatesToUpload extends SettingsEvent {}

final class SettingsUploadMindCandidates extends SettingsEvent {}

final class SettingsUpdateShouldShowTitlesMode extends SettingsEvent {
  final bool value;

  const SettingsUpdateShouldShowTitlesMode({required this.value});
}

final class SettingsChangeLanguage extends SettingsEvent {
  final SupportedLanguage language;

  const SettingsChangeLanguage({required this.language});
}

final class SettingsEnableDebugMenu extends SettingsEvent {
  const SettingsEnableDebugMenu();
}

final class SettingsTogglePhotoVideoSource extends SettingsEvent {
  final bool isEnabled;
  const SettingsTogglePhotoVideoSource({required this.isEnabled});
}

final class SettingsToggleWeatherSource extends SettingsEvent {
  final bool isEnabled;
  const SettingsToggleWeatherSource({required this.isEnabled});
}

final class SettingsUpdateWeatherLocation extends SettingsEvent {
  final double latitude;
  final double longitude;
  const SettingsUpdateWeatherLocation({required this.latitude, required this.longitude});
}

final class SettingsUpdateMediaFolderSource extends SettingsEvent {
  final bool? isEnabled;
  final String? folderPath;
  final bool? isRecursive;
  const SettingsUpdateMediaFolderSource({this.isEnabled, this.folderPath, this.isRecursive});
}
