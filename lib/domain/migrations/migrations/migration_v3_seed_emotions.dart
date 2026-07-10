// ignore_for_file: avoid_print

import 'package:keklist/domain/migrations/migration.dart';
import 'package:keklist/domain/services/entities/emotion.dart';
import 'package:uuid/uuid.dart';

/// Migration v3: Seed the default set of emotions.
///
/// On first run we populate five loose (folder-less) basic emotions so the
/// feature is usable out of the box. They are ordinary user data afterwards —
/// the user can rename, re-emoji, fold, archive or delete them.
///
/// Seeding is guarded both by the schema version (so it only runs once) and by
/// an emptiness check (so we never duplicate if a user already has emotions).
class MigrationV3SeedEmotions extends Migration {
  static const List<({String emoji, String title})> _defaults = [
    (emoji: '😠', title: 'Angry'),
    (emoji: '😨', title: 'Fear'),
    (emoji: '😢', title: 'Sad'),
    (emoji: '😄', title: 'Joy'),
    (emoji: '❤️', title: 'Love'),
  ];

  @override
  int get version => 3;

  @override
  String get description => 'Seed default emotions (Angry, Fear, Sad, Joy, Love)';

  @override
  Future<MigrationResult> run(MigrationContext context) async {
    try {
      final existing = await context.emotionRepository.obtainEmotions();
      if (existing.isNotEmpty) {
        print('[Migration v3] Emotions already present, skipping seed');
        return MigrationResult.success(message: 'skipped (already seeded)');
      }

      const uuid = Uuid();
      final now = DateTime.now();
      final emotions = <Emotion>[
        for (int i = 0; i < _defaults.length; i++)
          Emotion(
            id: uuid.v4(),
            title: _defaults[i].title,
            emoji: _defaults[i].emoji,
            parentId: null,
            isArchived: false,
            orderIndex: i,
            creationDate: now,
          ),
      ];

      await context.emotionRepository.createEmotions(emotions: emotions);
      print('[Migration v3] Seeded ${emotions.length} default emotions');
      return MigrationResult.success(message: 'seeded ${emotions.length} emotions');
    } catch (e, stackTrace) {
      print('[Migration v3] Fatal error: $e');
      print('[Migration v3] Stack trace: $stackTrace');
      return MigrationResult.failure(
        message: 'Failed to seed default emotions',
        error: e is Exception ? e : Exception(e.toString()),
      );
    }
  }
}
