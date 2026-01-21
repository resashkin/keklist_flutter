import 'package:flutter_test/flutter_test.dart';
import 'package:keklist/domain/migrations/migration.dart';
import 'package:keklist/domain/migrations/migrations/migration_v1_audio_duration.dart';
import 'package:keklist/domain/repositories/files/app_file_repository.dart';
import 'package:keklist/domain/repositories/mind/mind_repository.dart';
import 'package:keklist/domain/repositories/settings/settings_repository.dart';
import 'package:keklist/domain/services/entities/mind.dart';
import 'package:mocktail/mocktail.dart';

class MockMindRepository extends Mock implements MindRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(
      Mind(
        id: 'fallback',
        emoji: '🔄',
        note: 'fallback',
        dayIndex: 0,
        creationDate: DateTime(2024),
        sortIndex: 0,
        rootId: null,
      ),
    );
  });

  group('MigrationV1AudioDuration', () {
    late MigrationV1AudioDuration migration;
    late MockMindRepository mockMindRepo;
    late MockSettingsRepository mockSettingsRepo;
    late MigrationContext context;

    setUp(() {
      migration = MigrationV1AudioDuration();
      mockMindRepo = MockMindRepository();
      mockSettingsRepo = MockSettingsRepository();

      context = MigrationContext(
        mindRepository: mockMindRepo,
        settingsRepository: mockSettingsRepo,
        fileRepository: const AppFileRepository(),
      );
    });

    test('has version 1', () {
      expect(migration.version, 1);
    });

    test('has meaningful description', () {
      expect(migration.description, isNotEmpty);
      expect(migration.description.toLowerCase(), contains('duration'));
    });

    test('succeeds when no minds exist', () async {
      when(() => mockMindRepo.values).thenReturn([]);

      final result = await migration.run(context);

      expect(result.success, true);
      verifyNever(() => mockMindRepo.updateMind(mind: any(named: 'mind')));
    });

    test('skips minds without audio', () async {
      final mindWithoutAudio = Mind(
        id: '1',
        emoji: '📝',
        note: 'Just plain text',
        dayIndex: 0,
        creationDate: DateTime(2024),
        sortIndex: 0,
        rootId: null,
      );

      when(() => mockMindRepo.values).thenReturn([mindWithoutAudio]);

      final result = await migration.run(context);

      expect(result.success, true);
      verifyNever(() => mockMindRepo.updateMind(mind: any(named: 'mind')));
    });

    test('skips minds with audio that already have duration', () async {
      final mindWithDuration = Mind(
        id: '1',
        emoji: '🎵',
        note: 'Text<kekaudio path="/audio/file.m4a" duration="30.0"/>more',
        dayIndex: 0,
        creationDate: DateTime(2024),
        sortIndex: 0,
        rootId: null,
      );

      when(() => mockMindRepo.values).thenReturn([mindWithDuration]);

      final result = await migration.run(context);

      expect(result.success, true);
      verifyNever(() => mockMindRepo.updateMind(mind: any(named: 'mind')));
    });

    test('processes minds with old format audio (will set duration to 0 for missing files)', () async {
      // Note: This test doesn't actually test audio extraction because that
      // would require real audio files and AudioPlayer setup.
      // The migration will attempt to extract duration, but since the files
      // don't exist, it will set duration to 0.0

      final mindWithOldAudio = Mind(
        id: '1',
        emoji: '🎵',
        note: 'Text<kekaudio>/audio/nonexistent.m4a</kekaudio>more',
        dayIndex: 0,
        creationDate: DateTime(2024),
        sortIndex: 0,
        rootId: null,
      );

      when(() => mockMindRepo.values).thenReturn([mindWithOldAudio]);
      when(() => mockMindRepo.updateMind(mind: any(named: 'mind')))
          .thenAnswer((_) async {});

      final result = await migration.run(context);

      // Migration should complete (it will set duration to 0.0 for missing files)
      expect(result.success, true);

      // Verify updateMind was called
      verify(() => mockMindRepo.updateMind(mind: any(named: 'mind')))
          .called(1);
    });

    test('handles repository update errors gracefully', () async {
      final mindWithOldAudio = Mind(
        id: '1',
        emoji: '🎵',
        note: 'Text<kekaudio>/audio/file.m4a</kekaudio>',
        dayIndex: 0,
        creationDate: DateTime(2024),
        sortIndex: 0,
        rootId: null,
      );

      when(() => mockMindRepo.values).thenReturn([mindWithOldAudio]);
      when(() => mockMindRepo.updateMind(mind: any(named: 'mind')))
          .thenThrow(Exception('Update failed'));

      final result = await migration.run(context);

      // Migration should still succeed (errors are logged but not fatal for individual minds)
      expect(result.success, true);
      expect(result.message, contains('errors'));
    });
  });
}
