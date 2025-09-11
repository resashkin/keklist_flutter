import 'dart:async';

import 'package:keklist/domain/repositories/settings/object/settings_object.dart';

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
}

final class KeklistSettings {
  final bool isMindContentVisible;
  final String? previousAppVersion;
  final bool isDarkMode;
  final String? openAIKey;
  final bool shouldShowTitles;
  final String? userName;

  KeklistSettings({
    required this.isMindContentVisible,
    required this.previousAppVersion,
    required this.isDarkMode,
    required this.openAIKey,
    required this.shouldShowTitles,
    required this.userName,
  });

  SettingsObject toObject() => SettingsObject()
    ..isMindContentVisible = isMindContentVisible
    ..previousAppVersion = previousAppVersion
    ..isDarkMode = isDarkMode
    ..shouldShowTitles = shouldShowTitles
    ..openAIKey = openAIKey
    ..userName = userName;

  factory KeklistSettings.initial() => KeklistSettings(
        isMindContentVisible: true,
        previousAppVersion: null,
        isDarkMode: true,
        shouldShowTitles: true,
        openAIKey: null,
        userName: null,
      );
}
