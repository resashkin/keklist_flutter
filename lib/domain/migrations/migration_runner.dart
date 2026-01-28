// ignore_for_file: avoid_print

import 'package:keklist/domain/migrations/migration.dart';
import 'package:keklist/domain/migrations/migration_registry.dart';
import 'package:keklist/domain/repositories/files/app_file_repository.dart';
import 'package:keklist/domain/repositories/mind/mind_repository.dart';
import 'package:keklist/domain/repositories/settings/settings_repository.dart';

/// Orchestrates the execution of pending data migrations
class MigrationRunner {
  final SettingsRepository settingsRepository;
  final MindRepository mindRepository;
  final AppFileRepository fileRepository;

  const MigrationRunner({
    required this.settingsRepository,
    required this.mindRepository,
    required this.fileRepository,
  });

  /// Run all pending migrations (those with version > current dataSchemaVersion)
  /// Migrations are executed sequentially in version order
  /// Returns true if all migrations succeeded, false if any failed
  Future<bool> runPendingMigrations() async {
    try {
      final currentVersion = settingsRepository.value.dataSchemaVersion;
      print('[MigrationRunner] Current data schema version: $currentVersion');

      final allMigrations = MigrationRegistry.getAllMigrations();
      final pendingMigrations = allMigrations
          .where((migration) => migration.version > currentVersion)
          .toList();

      if (pendingMigrations.isEmpty) {
        print('[MigrationRunner] No pending migrations');
        return true;
      }

      print(
          '[MigrationRunner] Found ${pendingMigrations.length} pending migration(s)');

      final context = MigrationContext(
        mindRepository: mindRepository,
        settingsRepository: settingsRepository,
        fileRepository: fileRepository,
      );

      for (final migration in pendingMigrations) {
        print(
            '[MigrationRunner] Running migration v${migration.version}: ${migration.description}');

        try {
          final result = await migration.run(context);

          if (result.success) {
            print(
                '[MigrationRunner] Migration v${migration.version} succeeded${result.message != null ? ': ${result.message}' : ''}');

            // Update schema version after successful migration
            final updatedSettings = settingsRepository.value;
            await settingsRepository.updateSettings(
              KeklistSettings(
                isMindContentVisible: updatedSettings.isMindContentVisible,
                previousAppVersion: updatedSettings.previousAppVersion,
                isDarkMode: updatedSettings.isDarkMode,
                shouldShowTitles: updatedSettings.shouldShowTitles,
                userName: updatedSettings.userName,
                language: updatedSettings.language,
                dataSchemaVersion: migration.version,
              ),
            );

            print(
                '[MigrationRunner] Updated data schema version to ${migration.version}');
          } else {
            print(
                '[MigrationRunner] Migration v${migration.version} failed${result.message != null ? ': ${result.message}' : ''}');
            if (result.error != null) {
              print('[MigrationRunner] Error: ${result.error}');
            }
            return false;
          }
        } catch (e, stackTrace) {
          print(
              '[MigrationRunner] Migration v${migration.version} threw exception: $e');
          print('[MigrationRunner] Stack trace: $stackTrace');
          return false;
        }
      }

      print('[MigrationRunner] All migrations completed successfully');
      return true;
    } catch (e, stackTrace) {
      print('[MigrationRunner] Fatal error running migrations: $e');
      print('[MigrationRunner] Stack trace: $stackTrace');
      return false;
    }
  }
}
