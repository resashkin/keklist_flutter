import 'package:hive_flutter/hive_flutter.dart';
import 'package:keklist/domain/repositories/settings/settings_repository.dart';

part 'settings_object.g.dart';

@HiveType(typeId: 0)
final class SettingsObject extends HiveObject {
  @HiveField(0, defaultValue: true)
  late bool isMindContentVisible;

  @HiveField(1, defaultValue: null)
  late String? previousAppVersion;

  @HiveField(2, defaultValue: true)
  late bool isOfflineMode;

  @HiveField(3, defaultValue: true)
  late bool isDarkMode;

  @HiveField(4, defaultValue: null)
  late String? openAIKey = '';

  @HiveField(5, defaultValue: true)
  late bool shouldShowTitles;

  @HiveField(6, defaultValue: null)
  late String? userName;

  SettingsObject();

  KeklistSettings toSettings() => KeklistSettings(
        isMindContentVisible: isMindContentVisible,
        previousAppVersion: previousAppVersion,
        isOfflineMode: isOfflineMode,
        openAIKey: openAIKey,
        shouldShowTitles: shouldShowTitles,
        isDarkMode: isDarkMode,
        userName: userName,
      );
}
