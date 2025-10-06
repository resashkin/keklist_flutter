part of 'settings_bloc.dart';

sealed class SettingsEvent {
  const SettingsEvent();
}

final class SettingsGet extends SettingsEvent {}

final class SettingsExport extends SettingsEvent {
  final SettingsExportType type;

  SettingsExport({required this.type});
}

final class SettingsImport extends SettingsEvent {
  final SettingsImportType type;

  SettingsImport({required this.type});
}

enum SettingsExportType { csv }

enum SettingsImportType { csv }

final class SettingsExportAllMindsToCSV extends SettingsEvent {}

// final class SettingsExportMindsToEncryptedImage extends SettingsEvent {
//   final PeriodType periodType;

//   SettingsExportMindsToEncryptedImage({required this.periodType});
// }

// final class SettingsImportAllMindsFromEncryptedImage extends SettingsEvent {}

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

final class SettingsChangeOpenAIKey extends SettingsEvent {
  final String openAIToken;

  const SettingsChangeOpenAIKey({required this.openAIToken});
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
