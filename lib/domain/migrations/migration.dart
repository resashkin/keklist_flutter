import 'package:keklist/domain/repositories/files/app_file_repository.dart';
import 'package:keklist/domain/repositories/mind/mind_repository.dart';
import 'package:keklist/domain/repositories/settings/settings_repository.dart';

/// Base class for all data migrations
abstract class Migration {
  /// Version number for this migration (must be unique and sequential)
  int get version;

  /// Human-readable description of what this migration does
  String get description;

  /// Execute the migration
  /// Returns a MigrationResult indicating success or failure
  Future<MigrationResult> run(MigrationContext context);
}

/// Context object providing access to repositories needed during migration
class MigrationContext {
  final MindRepository mindRepository;
  final SettingsRepository settingsRepository;
  final AppFileRepository fileRepository;

  const MigrationContext({
    required this.mindRepository,
    required this.settingsRepository,
    required this.fileRepository,
  });
}

/// Result of a migration execution
class MigrationResult {
  final bool success;
  final String? message;
  final Exception? error;

  const MigrationResult({
    required this.success,
    this.message,
    this.error,
  });

  factory MigrationResult.success({String? message}) => MigrationResult(
        success: true,
        message: message,
      );

  factory MigrationResult.failure({String? message, Exception? error}) =>
      MigrationResult(
        success: false,
        message: message,
        error: error,
      );
}
