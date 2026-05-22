// ignore_for_file: avoid_print

import 'package:keklist/domain/migrations/migration.dart';

/// Migration v2: Migrate isDarkMode bool to KeklistThemeMode enum
///
/// Before this migration, theme was stored as isDarkMode (bool).
/// After this migration, themePreferenceIndex (int) is the authoritative field.
/// The SettingsObject.toSettings() handles the -1 sentinel by falling back to
/// isDarkMode, so the app displays the correct theme even before this runs.
class MigrationV2ThemePreference extends Migration {
  @override
  int get version => 2;

  @override
  String get description => 'Migrate isDarkMode bool to themePreferenceIndex enum';

  @override
  Future<MigrationResult> run(MigrationContext context) async {
    try {
      print('[Migration v2] Migrating theme preference');
      final currentSettings = context.settingsRepository.value;
      await context.settingsRepository.updateThemePreference(currentSettings.themePreference);
      print('[Migration v2] Theme preference migrated: ${currentSettings.themePreference}');
      return MigrationResult.success(message: 'themePreference=${currentSettings.themePreference}');
    } catch (e, stackTrace) {
      print('[Migration v2] Fatal error: $e');
      print('[Migration v2] Stack trace: $stackTrace');
      return MigrationResult.failure(
        message: 'Failed to migrate theme preference',
        error: e is Exception ? e : Exception(e.toString()),
      );
    }
  }
}
