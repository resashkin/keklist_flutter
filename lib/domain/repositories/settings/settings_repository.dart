import 'dart:async';
import 'dart:ui';

import 'package:keklist/domain/repositories/settings/object/settings_object.dart';
import 'package:keklist/domain/services/language_manager.dart';

abstract class SettingsRepository {
  KeklistSettings get value;
  Stream<KeklistSettings> get stream;
  FutureOr<void> updateUserName(String string);
  FutureOr<void> updateSettings(KeklistSettings settings);
  FutureOr<void> updateOpenAIKey(String? openAIKey);
  FutureOr<void> updateDarkMode(bool isDarkMode);
  FutureOr<void> updateMindContentVisibility(bool isVisible);
  FutureOr<void> updateShouldShowTitles(bool shouldShowTitles);
  FutureOr<void> updatePreviousAppVersion(String? previousAppVersion);
  FutureOr<void> updateLanguage(SupportedLanguage language);
  FutureOr<void> updateHasSeenOnboarding(bool hasSeenOnboarding);
}

final class KeklistSettings {
  final bool isMindContentVisible;
  final String? previousAppVersion;
  final bool isDarkMode;
  final String? openAIKey;
  final bool shouldShowTitles;
  final String? userName;
  final SupportedLanguage language;
  final bool hasSeenOnboarding;

  KeklistSettings({
    required this.isMindContentVisible,
    required this.previousAppVersion,
    required this.isDarkMode,
    required this.openAIKey,
    required this.shouldShowTitles,
    required this.userName,
    required this.language,
    required this.hasSeenOnboarding,
  });

  SettingsObject toObject() => SettingsObject()
    ..isMindContentVisible = isMindContentVisible
    ..previousAppVersion = previousAppVersion
    ..isDarkMode = isDarkMode
    ..shouldShowTitles = shouldShowTitles
    ..openAIKey = openAIKey
    ..userName = userName
    ..language = language.code
    ..hasSeenOnboarding = hasSeenOnboarding;

  factory KeklistSettings.initial() => KeklistSettings(
        isMindContentVisible: true,
        previousAppVersion: null,
        isDarkMode: true,
        shouldShowTitles: true,
        openAIKey: null,
        userName: null,
        language: _detectDeviceLocale(),
        hasSeenOnboarding: false,
      );

  /// Detect device locale and return supported language or fallback to English
  static SupportedLanguage _detectDeviceLocale() {
    final deviceLocale = PlatformDispatcher.instance.locale;
    final deviceLanguageCode = deviceLocale.languageCode;
    final deviceScriptCode = deviceLocale.scriptCode;

    // Special handling for Serbian with script detection
    if (deviceLanguageCode == 'sr') {
      if (deviceScriptCode == 'Latn') {
        return SupportedLanguage.serbianLatin;
      } else {
        return SupportedLanguage.serbian;
      }
    }

    // Try to find exact match
    for (final language in SupportedLanguage.values) {
      if (language.code == deviceLanguageCode) {
        return language;
      }
    }

    // Try to find partial match (e.g., 'zh-CN' -> 'zh')
    for (final language in SupportedLanguage.values) {
      if (deviceLanguageCode.startsWith(language.code)) {
        return language;
      }
    }

    // Fallback to English
    return SupportedLanguage.english;
  }
}
