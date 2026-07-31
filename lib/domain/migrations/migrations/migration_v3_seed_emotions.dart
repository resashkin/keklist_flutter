import 'package:keklist/domain/migrations/migration.dart';

/// Migration v3: reserved, no-op.
///
/// This slot used to seed five hardcoded **English** emotions at startup.
/// Seeding now happens on first open of the emotion marker, in the user's own
/// language, via `EmotionSeedDefaults` — see
/// `documentation/adr/ADR-0003-localized-emotion-seeding.md`.
///
/// The class is kept so the version number stays consumed: installs that already
/// recorded schema version 3 must never see a *different* v3 appear later and
/// silently skip it.
class MigrationV3SeedEmotions extends Migration {
  @override
  int get version => 3;

  @override
  String get description => 'Reserved (emotions are seeded on first marker open)';

  @override
  Future<MigrationResult> run(MigrationContext context) async {
    return MigrationResult.success(message: 'no-op (superseded by first-open seeding)');
  }
}
