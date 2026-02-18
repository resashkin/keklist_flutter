import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keklist/domain/repositories/mind/mind_repository.dart';
import 'package:keklist/domain/repositories/settings/settings_repository.dart';
import 'package:keklist/domain/services/constants/onboarding_constants.dart';
import 'package:keklist/domain/services/entities/mind.dart';
import 'package:keklist/domain/services/language_manager.dart';
import 'package:keklist/presentation/blocs/lazy_onboarding_bloc/lazy_onboarding_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockMindRepository extends Mock implements MindRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockBuildContext extends Mock implements BuildContext {}

void main() {
  late MockMindRepository mockMindRepository;
  late MockSettingsRepository mockSettingsRepository;
  late LazyOnboardingBloc bloc;

  setUp(() {
    mockMindRepository = MockMindRepository();
    mockSettingsRepository = MockSettingsRepository();

    bloc = LazyOnboardingBloc(
      mindRepository: mockMindRepository,
      settingsRepository: mockSettingsRepository,
    );

    // Register fallback values
    registerFallbackValue(
      KeklistSettings(
        isMindContentVisible: true,
        previousAppVersion: null,
        isDarkMode: true,
        shouldShowTitles: true,
        userName: null,
        language: SupportedLanguage.english,
        dataSchemaVersion: 0,
        hasSeenLazyOnboarding: false,
        isDebugMenuVisible: false,
        isPhotoVideoSourceEnabled: false,
      ),
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('LazyOnboardingCheck', () {
    test('should emit LazyOnboardingNeeded(shouldShow: false) when user has already seen onboarding', () async {
      // Arrange
      when(() => mockSettingsRepository.value).thenReturn(
        KeklistSettings(
          isMindContentVisible: true,
          previousAppVersion: null,
          isDarkMode: true,
          shouldShowTitles: true,
          userName: null,
          language: SupportedLanguage.english,
          dataSchemaVersion: 0,
          hasSeenLazyOnboarding: true,
          isDebugMenuVisible: false,
          isPhotoVideoSourceEnabled: false,
        ),
      );

      // Act & Assert
      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<LazyOnboardingNeeded>().having((state) => state.shouldShow, 'shouldShow', false),
        ]),
      );

      bloc.add(LazyOnboardingCheck());
    });

    test('should emit LazyOnboardingNeeded(shouldShow: true) when totalMinds < 10', () async {
      // Arrange
      when(() => mockSettingsRepository.value).thenReturn(
        KeklistSettings(
          isMindContentVisible: true,
          previousAppVersion: null,
          isDarkMode: true,
          shouldShowTitles: true,
          userName: null,
          language: SupportedLanguage.english,
          dataSchemaVersion: 0,
          hasSeenLazyOnboarding: false,
          isDebugMenuVisible: false,
          isPhotoVideoSourceEnabled: false,
        ),
      );

      when(() => mockMindRepository.obtainMinds()).thenAnswer((_) async => [
            _createMind(id: '1', dayIndex: 0),
            _createMind(id: '2', dayIndex: 1),
          ]);

      // Act & Assert
      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<LazyOnboardingNeeded>().having((state) => state.shouldShow, 'shouldShow', true),
        ]),
      );

      bloc.add(LazyOnboardingCheck());
    });

    test('should emit LazyOnboardingNeeded(shouldShow: true) when no minds in last 30 days', () async {
      // Arrange
      final now = DateTime.now();
      final oldDate = now.subtract(const Duration(days: 60));
      final oldDayIndex = _getDayIndex(oldDate);

      when(() => mockSettingsRepository.value).thenReturn(
        KeklistSettings(
          isMindContentVisible: true,
          previousAppVersion: null,
          isDarkMode: true,
          shouldShowTitles: true,
          userName: null,
          language: SupportedLanguage.english,
          dataSchemaVersion: 0,
          hasSeenLazyOnboarding: false,
          isDebugMenuVisible: false,
          isPhotoVideoSourceEnabled: false,
        ),
      );

      when(() => mockMindRepository.obtainMinds()).thenAnswer((_) async => [
            _createMind(id: '1', dayIndex: oldDayIndex),
            _createMind(id: '2', dayIndex: oldDayIndex),
            _createMind(id: '3', dayIndex: oldDayIndex),
            _createMind(id: '4', dayIndex: oldDayIndex),
            _createMind(id: '5', dayIndex: oldDayIndex),
            _createMind(id: '6', dayIndex: oldDayIndex),
            _createMind(id: '7', dayIndex: oldDayIndex),
            _createMind(id: '8', dayIndex: oldDayIndex),
            _createMind(id: '9', dayIndex: oldDayIndex),
            _createMind(id: '10', dayIndex: oldDayIndex),
            _createMind(id: '11', dayIndex: oldDayIndex),
          ]);

      // Act & Assert
      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<LazyOnboardingNeeded>().having((state) => state.shouldShow, 'shouldShow', true),
        ]),
      );

      bloc.add(LazyOnboardingCheck());
    });

    test('should emit LazyOnboardingNeeded(shouldShow: false) when conditions not met', () async {
      // Arrange
      final todayDayIndex = _getDayIndex(DateTime.now());

      when(() => mockSettingsRepository.value).thenReturn(
        KeklistSettings(
          isMindContentVisible: true,
          previousAppVersion: null,
          isDarkMode: true,
          shouldShowTitles: true,
          userName: null,
          language: SupportedLanguage.english,
          dataSchemaVersion: 0,
          hasSeenLazyOnboarding: false,
          isDebugMenuVisible: false,
          isPhotoVideoSourceEnabled: false,
        ),
      );

      when(() => mockMindRepository.obtainMinds()).thenAnswer((_) async => [
            _createMind(id: '1', dayIndex: todayDayIndex),
            _createMind(id: '2', dayIndex: todayDayIndex),
            _createMind(id: '3', dayIndex: todayDayIndex),
            _createMind(id: '4', dayIndex: todayDayIndex),
            _createMind(id: '5', dayIndex: todayDayIndex),
            _createMind(id: '6', dayIndex: todayDayIndex),
            _createMind(id: '7', dayIndex: todayDayIndex),
            _createMind(id: '8', dayIndex: todayDayIndex),
            _createMind(id: '9', dayIndex: todayDayIndex),
            _createMind(id: '10', dayIndex: todayDayIndex),
            _createMind(id: '11', dayIndex: todayDayIndex),
          ]);

      // Act & Assert
      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<LazyOnboardingNeeded>().having((state) => state.shouldShow, 'shouldShow', false),
        ]),
      );

      bloc.add(LazyOnboardingCheck());
    });
  });

  group('LazyOnboardingCreate', () {
    test('should create onboarding minds with correct structure', () async {
      // NOTE: This test only verifies structure (counts, IDs, relationships)
      // It does NOT validate string content - existence is sufficient

      // Arrange
      final mockContext = MockBuildContext();

      // Mock the BuildContext to return null for localization lookup
      // This will cause the extension to use AppLocalizationsEn() as fallback
      when(() => mockContext.dependOnInheritedWidgetOfExactType<InheritedWidget>()).thenReturn(null);

      List<Mind> createdMinds = [];
      when(() => mockMindRepository.createMinds(minds: any(named: 'minds'))).thenAnswer((invocation) async {
        createdMinds = (invocation.namedArguments[const Symbol('minds')] as Iterable<Mind>).toList();
      });

      // Act
      bloc.add(LazyOnboardingCreate(context: mockContext));
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert - Only verify structure, not content
      verify(() => mockMindRepository.createMinds(minds: any(named: 'minds'))).called(1);

      // Verify minds were created (existence check only)
      expect(createdMinds.isNotEmpty, true);
      expect(createdMinds.length, 8);

      // Verify parent minds have correct structure
      final parentMinds = createdMinds.where((m) => m.rootId == null).toList();
      expect(parentMinds.length, 6);

      // All parent minds should have ONBOARDING_ prefix
      for (final parent in parentMinds) {
        expect(parent.id.startsWith(OnboardingConstants.onboardingIdPrefix), true);
        expect(parent.rootId, null);
      }

      // Verify comment minds have correct structure
      final commentMinds = createdMinds.where((m) => m.rootId != null).toList();
      expect(commentMinds.length, 2);

      // All comments should reference a parent mind
      for (final comment in commentMinds) {
        expect(OnboardingConstants.isOnboardingMindId(comment.rootId!), true);
        expect(parentMinds.any((p) => p.id == comment.rootId), true);
      }
    });

    test('should verify ID prefix helper works correctly', () {
      const prefix = OnboardingConstants.onboardingIdPrefix;
      final testId = '${prefix}test-123';

      expect(OnboardingConstants.isOnboardingMindId(testId), true);
      expect(OnboardingConstants.isOnboardingMind(testId, null), true);
      expect(OnboardingConstants.isOnboardingMindId('regular-id'), false);
    });
  });

  group('LazyOnboardingDelete', () {
    test('should delete all onboarding parent and comment minds', () async {
      // Arrange
      final onboardingParentId1 = '${OnboardingConstants.onboardingIdPrefix}parent-1';
      final onboardingParentId2 = '${OnboardingConstants.onboardingIdPrefix}parent-2';
      final commentId1 = 'comment-1';
      final commentId2 = 'comment-2';

      when(() => mockMindRepository.obtainMinds()).thenAnswer((_) async => [
            _createMind(id: onboardingParentId1, rootId: null, dayIndex: 0),
            _createMind(id: onboardingParentId2, rootId: null, dayIndex: 0),
            _createMind(id: commentId1, rootId: onboardingParentId1, dayIndex: 0),
            _createMind(id: commentId2, rootId: onboardingParentId2, dayIndex: 0),
          ]);

      when(() => mockMindRepository.deleteMindsWhere(any())).thenAnswer((_) async {});

      // Act
      bloc.add(LazyOnboardingDelete());
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      verify(() => mockMindRepository.deleteMindsWhere(any())).called(2);
      verify(() => mockMindRepository.obtainMinds()).called(1);
    });
  });

  group('LazyOnboardingMarkAsSeen', () {
    test('should update settings with hasSeenLazyOnboarding = true', () async {
      // Arrange
      final currentSettings = KeklistSettings(
        isMindContentVisible: true,
        previousAppVersion: null,
        isDarkMode: true,
        shouldShowTitles: true,
        userName: null,
        language: SupportedLanguage.english,
        dataSchemaVersion: 0,
        hasSeenLazyOnboarding: false,
        isDebugMenuVisible: false,
        isPhotoVideoSourceEnabled: false,
      );

      when(() => mockSettingsRepository.value).thenReturn(currentSettings);
      when(() => mockSettingsRepository.updateSettings(any())).thenAnswer((_) async {});

      // Act
      bloc.add(LazyOnboardingMarkAsSeen());
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      final captured = verify(() => mockSettingsRepository.updateSettings(captureAny())).captured;
      expect(captured.length, 1);
      final updatedSettings = captured.first as KeklistSettings;
      expect(updatedSettings.hasSeenLazyOnboarding, true);
    });
  });

  group('OnboardingConstants helpers', () {
    test('isOnboardingMindId should correctly identify onboarding mind IDs', () {
      expect(OnboardingConstants.isOnboardingMindId('ONBOARDING_123'), true);
      expect(OnboardingConstants.isOnboardingMindId('ONBOARDING_abc-def'), true);
      expect(OnboardingConstants.isOnboardingMindId('regular-mind-id'), false);
      expect(OnboardingConstants.isOnboardingMindId('123'), false);
    });

    test('isOnboardingMind should correctly identify onboarding minds', () {
      // Parent onboarding mind
      expect(OnboardingConstants.isOnboardingMind('ONBOARDING_123', null), true);

      // Child of onboarding mind
      expect(OnboardingConstants.isOnboardingMind('comment-id', 'ONBOARDING_parent'), true);

      // Regular parent mind
      expect(OnboardingConstants.isOnboardingMind('regular-id', null), false);

      // Regular child mind
      expect(OnboardingConstants.isOnboardingMind('child-id', 'parent-id'), false);
    });
  });
}

// Helper functions
Mind _createMind({
  required String id,
  required int dayIndex,
  String? rootId,
}) {
  return Mind(
    id: id,
    emoji: '😊',
    note: 'Test note',
    dayIndex: dayIndex,
    creationDate: DateTime.now(),
    sortIndex: 0,
    rootId: rootId,
  );
}

int _getDayIndex(DateTime date) {
  const millisecondsInDay = 1000 * 60 * 60 * 24;
  return (date.millisecondsSinceEpoch + date.timeZoneOffset.inMilliseconds) ~/ millisecondsInDay;
}
