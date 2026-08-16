import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:keklist/domain/repositories/settings/keklist_interface_style.dart';
import 'package:keklist/domain/repositories/settings/keklist_theme_mode.dart';
import 'package:keklist/domain/repositories/settings/settings_repository.dart';
import 'package:keklist/domain/services/language_manager.dart';

part 'settings_object.g.dart';

@HiveType(typeId: 0)
final class SettingsObject extends HiveObject {
  @HiveField(0, defaultValue: true)
  late bool isMindContentVisible;

  @HiveField(1, defaultValue: null)
  late String? previousAppVersion;

  // @HiveField(2, defaultValue: false)

  @HiveField(3, defaultValue: true)
  late bool isDarkMode;

  @HiveField(5, defaultValue: true)
  late bool shouldShowTitles;

  @HiveField(6, defaultValue: null)
  late String? userName;

  @HiveField(7, defaultValue: 'en')
  late String language;

  @HiveField(8, defaultValue: 0)
  late int dataSchemaVersion;

  @HiveField(9, defaultValue: false)
  late bool hasSeenLazyOnboarding;

  @HiveField(10, defaultValue: false)
  late bool isDebugMenuVisible;

  @HiveField(11, defaultValue: false)
  late bool isPhotoVideoSourceEnabled;

  @HiveField(12, defaultValue: false)
  late bool isWeatherSourceEnabled;

  @HiveField(13, defaultValue: null)
  late double? weatherLatitude;

  @HiveField(14, defaultValue: null)
  late double? weatherLongitude;

  @HiveField(15, defaultValue: false)
  late bool isMediaFolderSourceEnabled;

  @HiveField(16, defaultValue: null)
  late String? mediaFolderPath;

  @HiveField(17, defaultValue: false)
  late bool isMediaFolderRecursive;

  // -1 = not yet migrated (fall back to isDarkMode); >= 0 = KeklistThemeMode.index
  @HiveField(18, defaultValue: -1)
  late int themePreferenceIndex;

  // Default 1 = Liquid Glass; platform gating forces Material on non-iOS at read time.
  @HiveField(19, defaultValue: 1)
  late int interfaceStyleIndex;

  @HiveField(20, defaultValue: false)
  late bool hasSeededEmotions;

  SettingsObject();

  KeklistSettings toSettings() => KeklistSettings(
        isMindContentVisible: isMindContentVisible,
        previousAppVersion: previousAppVersion,
        shouldShowTitles: shouldShowTitles,
        themePreference: themePreferenceIndex < 0
            ? (isDarkMode ? KeklistThemeMode.dark : KeklistThemeMode.light)
            : KeklistThemeMode.fromIndex(themePreferenceIndex),
        interfaceStyle: KeklistInterfaceStyle.fromIndex(interfaceStyleIndex),
        userName: userName,
        language: SupportedLanguage.fromCode(language),
        dataSchemaVersion: dataSchemaVersion,
        hasSeenLazyOnboarding: hasSeenLazyOnboarding,
        isDebugMenuVisible: isDebugMenuVisible,
        isPhotoVideoSourceEnabled: isPhotoVideoSourceEnabled,
        isWeatherSourceEnabled: isWeatherSourceEnabled,
        weatherLatitude: weatherLatitude,
        weatherLongitude: weatherLongitude,
        isMediaFolderSourceEnabled: isMediaFolderSourceEnabled,
        mediaFolderPath: mediaFolderPath,
        isMediaFolderRecursive: isMediaFolderRecursive,
        hasSeededEmotions: hasSeededEmotions,
      );
}
