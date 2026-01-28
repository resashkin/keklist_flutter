import 'package:keklist/domain/migrations/migration.dart';
import 'package:keklist/domain/migrations/migrations/migration_v1_audio_duration.dart';

/// Central registry of all data migrations
/// Migrations are executed in order by version number
class MigrationRegistry {
  /// Get all available migrations in the application
  /// Returns migrations sorted by version number (ascending)
  static List<Migration> getAllMigrations() {
    final migrations = <Migration>[
      MigrationV1AudioDuration(),
      // Future migrations will be added here:
      // MigrationV2Transcription(),
      // MigrationV3AudioCodec(),
    ];

    // Sort by version to ensure consistent execution order
    migrations.sort((a, b) => a.version.compareTo(b.version));

    return migrations;
  }
}
