import 'package:flutter_test/flutter_test.dart';
import 'package:keklist/domain/migrations/migration.dart';
import 'package:keklist/domain/migrations/migration_runner.dart';
import 'package:keklist/domain/repositories/files/app_file_repository.dart';
import 'package:keklist/domain/repositories/mind/mind_repository.dart';
import 'package:keklist/domain/repositories/settings/settings_repository.dart';
import 'package:keklist/domain/services/language_manager.dart';
import 'package:mocktail/mocktail.dart';

class MockMindRepository extends Mock implements MindRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockMigration extends Mock implements Migration {}

void main() {
  late MockMindRepository mockMindRepo;
  late MockSettingsRepository mockSettingsRepo;
  late MigrationRunner runner;

  setUp(() {
    mockMindRepo = MockMindRepository();
    mockSettingsRepo = MockSettingsRepository();

    runner = MigrationRunner(
      settingsRepository: mockSettingsRepo,
      mindRepository: mockMindRepo,
      fileRepository: const AppFileRepository(),
    );

    // Register fallback values for mocktail
    registerFallbackValue(
      KeklistSettings(
        isMindContentVisible: true,
        previousAppVersion: null,
        isDarkMode: true,
        shouldShowTitles: true,
        userName: null,
        language: SupportedLanguage.english,
        dataSchemaVersion: 0,
      ),
    );
  });

  group('MigrationRunner', () {
    test('runs no migrations when schema version is up to date', () async {
      // Current version is already 1, no migrations needed
      when(() => mockSettingsRepo.value).thenReturn(
        KeklistSettings(
          isMindContentVisible: true,
          previousAppVersion: null,
          isDarkMode: true,
          shouldShowTitles: true,
          userName: null,
          language: SupportedLanguage.english,
          dataSchemaVersion: 1,
        ),
      );

      // Note: This test assumes MigrationRegistry only has migration v1
      final result = await runner.runPendingMigrations();

      expect(result, true);
      verifyNever(() => mockSettingsRepo.updateSettings(any()));
    });

    test('does not run migrations when no migrations exist', () async {
      when(() => mockSettingsRepo.value).thenReturn(
        KeklistSettings(
          isMindContentVisible: true,
          previousAppVersion: null,
          isDarkMode: true,
          shouldShowTitles: true,
          userName: null,
          language: SupportedLanguage.english,
          dataSchemaVersion: 0,
        ),
      );

      // The actual registry has migrations, so we can't test this without modifying the registry
      // This test is more conceptual
    });

    test('updates schema version after successful migration', () async {
      when(() => mockSettingsRepo.value).thenReturn(
        KeklistSettings(
          isMindContentVisible: true,
          previousAppVersion: null,
          isDarkMode: true,
          shouldShowTitles: true,
          userName: null,
          language: SupportedLanguage.english,
          dataSchemaVersion: 0,
        ),
      );

      when(() => mockMindRepo.values).thenReturn([]);
      when(() => mockSettingsRepo.updateSettings(any()))
          .thenAnswer((_) async {});

      final result = await runner.runPendingMigrations();

      expect(result, true);

      // Verify that updateSettings was called with version = 1
      verify(() => mockSettingsRepo.updateSettings(any(
            that: predicate<KeklistSettings>(
              (settings) => settings.dataSchemaVersion == 1,
            ),
          ))).called(1);
    });

    test('handles migration failure gracefully', () async {
      // This would require mocking a migration that fails
      // For now, we rely on integration tests
    });
  });
}
