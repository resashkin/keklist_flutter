import 'package:keklist/domain/repositories/mind/mind_repository.dart';
import 'package:keklist/domain/services/entities/mind.dart';
import 'package:keklist/l10n/app_localizations.dart';
import 'package:keklist/presentation/core/helpers/date_utils.dart';
import 'package:uuid/uuid.dart';

class OnboardingService {
  static Future<void> createSampleMinds({
    required MindRepository mindRepository,
    required AppLocalizations localizations,
  }) async {
    final int todayIndex = DateUtils.getTodayIndex();
    final DateTime now = DateTime.now().toUtc();

    // Create 4 sample minds with instructions
    final List<Mind> sampleMinds = [
      Mind(
        id: const Uuid().v4(),
        dayIndex: todayIndex,
        note: localizations.onboardingSampleMind1,
        emoji: '👋',
        creationDate: now.subtract(const Duration(minutes: 30)),
        sortIndex: 0,
        rootId: null,
      ),
      Mind(
        id: const Uuid().v4(),
        dayIndex: todayIndex,
        note: localizations.onboardingSampleMind2,
        emoji: '😊',
        creationDate: now.subtract(const Duration(minutes: 20)),
        sortIndex: 1,
        rootId: null,
      ),
      Mind(
        id: const Uuid().v4(),
        dayIndex: todayIndex,
        note: localizations.onboardingSampleMind3,
        emoji: '📝',
        creationDate: now.subtract(const Duration(minutes: 10)),
        sortIndex: 2,
        rootId: null,
      ),
      Mind(
        id: const Uuid().v4(),
        dayIndex: todayIndex,
        note: localizations.onboardingSampleMind4,
        emoji: '🚀',
        creationDate: now,
        sortIndex: 3,
        rootId: null,
      ),
    ];

    await mindRepository.createMinds(minds: sampleMinds);
  }
}
