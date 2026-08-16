import 'package:flutter_test/flutter_test.dart';
import 'package:keklist/domain/repositories/emotion/emotion_repository.dart';
import 'package:keklist/domain/repositories/mind/mind_repository.dart';
import 'package:keklist/domain/repositories/settings/keklist_interface_style.dart';
import 'package:keklist/domain/repositories/settings/keklist_theme_mode.dart';
import 'package:keklist/domain/repositories/settings/settings_repository.dart';
import 'package:keklist/domain/services/entities/emotion.dart';
import 'package:keklist/domain/services/entities/emotion_seed.dart';
import 'package:keklist/domain/services/language_manager.dart';
import 'package:keklist/presentation/blocs/emotion_bloc/emotion_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockEmotionRepository extends Mock implements EmotionRepository {}

class MockMindRepository extends Mock implements MindRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

KeklistSettings _settings({
  required SupportedLanguage language,
  required bool hasSeededEmotions,
}) =>
    KeklistSettings(
      isMindContentVisible: true,
      previousAppVersion: null,
      themePreference: KeklistThemeMode.system,
      interfaceStyle: KeklistInterfaceStyle.liquidGlass,
      shouldShowTitles: true,
      userName: null,
      language: language,
      dataSchemaVersion: 3,
      hasSeenLazyOnboarding: false,
      isDebugMenuVisible: false,
      isPhotoVideoSourceEnabled: false,
      hasSeededEmotions: hasSeededEmotions,
    );

Emotion _emotion(String id) => Emotion(
      id: id,
      title: id,
      emoji: '🙂',
      parentId: null,
      isArchived: false,
      orderIndex: 0,
      creationDate: DateTime.utc(2026),
    );

void main() {
  late MockEmotionRepository emotionRepository;
  late MockMindRepository mindRepository;
  late MockSettingsRepository settingsRepository;

  setUp(() {
    emotionRepository = MockEmotionRepository();
    mindRepository = MockMindRepository();
    settingsRepository = MockSettingsRepository();

    registerFallbackValue(<Emotion>[]);
    when(() => emotionRepository.stream).thenAnswer((_) => const Stream.empty());
    when(() => emotionRepository.values).thenReturn(const []);
    when(() => emotionRepository.createEmotions(emotions: any(named: 'emotions'))).thenAnswer((_) async {});
    when(() => settingsRepository.updateHasSeededEmotions(any())).thenAnswer((_) async {});
  });

  EmotionBloc buildBloc() => EmotionBloc(
        emotionRepository: emotionRepository,
        mindRepository: mindRepository,
        settingsRepository: settingsRepository,
      );

  group('EmotionSeedDefaults', () {
    test('seeds the five starter emotions in the settings language', () async {
      when(() => settingsRepository.value)
          .thenReturn(_settings(language: SupportedLanguage.russian, hasSeededEmotions: false));
      when(() => emotionRepository.obtainEmotions()).thenAnswer((_) async => const []);

      final bloc = buildBloc();
      bloc.add(EmotionSeedDefaults());
      await Future<void>.delayed(Duration.zero);

      final captured = verify(
        () => emotionRepository.createEmotions(emotions: captureAny(named: 'emotions')),
      ).captured.single as List<Emotion>;

      expect(captured.map((e) => e.title), ['Злость', 'Страх', 'Грусть', 'Радость', 'Любовь']);
      expect(captured.map((e) => e.emoji), EmotionSeed.emojis);
      expect(captured.map((e) => e.orderIndex), [0, 1, 2, 3, 4]);
      expect(captured.every((e) => e.parentId == null && !e.isArchived), isTrue);
      verify(() => settingsRepository.updateHasSeededEmotions(true)).called(1);

      await bloc.close();
    });

    test('does nothing once the flag is set, even with an empty store', () async {
      when(() => settingsRepository.value)
          .thenReturn(_settings(language: SupportedLanguage.english, hasSeededEmotions: true));
      when(() => emotionRepository.obtainEmotions()).thenAnswer((_) async => const []);

      final bloc = buildBloc();
      bloc.add(EmotionSeedDefaults());
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => emotionRepository.createEmotions(emotions: any(named: 'emotions')));

      await bloc.close();
    });

    // The branch that protects a store created before the flag existed.
    test('never duplicates onto an existing set; just records the flag', () async {
      when(() => settingsRepository.value)
          .thenReturn(_settings(language: SupportedLanguage.english, hasSeededEmotions: false));
      when(() => emotionRepository.obtainEmotions()).thenAnswer((_) async => [_emotion('mine')]);

      final bloc = buildBloc();
      bloc.add(EmotionSeedDefaults());
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => emotionRepository.createEmotions(emotions: any(named: 'emotions')));
      verify(() => settingsRepository.updateHasSeededEmotions(true)).called(1);

      await bloc.close();
    });

    test('falls back to English for a language missing from the seed map', () {
      final titles = EmotionSeed.forLanguage(SupportedLanguage.english).map((e) => e.title);
      expect(titles, ['Angry', 'Fear', 'Sad', 'Joy', 'Love']);
      for (final language in SupportedLanguage.values) {
        expect(EmotionSeed.forLanguage(language).length, EmotionSeed.emojis.length,
            reason: 'every supported language must yield a full seed set');
      }
    });
  });
}
