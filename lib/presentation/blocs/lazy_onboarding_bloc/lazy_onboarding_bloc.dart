import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:keklist/domain/repositories/mind/mind_repository.dart';
import 'package:keklist/domain/repositories/settings/settings_repository.dart';
import 'package:keklist/domain/services/constants/onboarding_constants.dart';
import 'package:keklist/domain/services/entities/mind.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';
import 'package:keklist/presentation/core/helpers/date_utils.dart' as kek_date_utils;
import 'package:keklist/presentation/core/helpers/mind_utils.dart';
import 'package:uuid/uuid.dart';

part 'lazy_onboarding_event.dart';
part 'lazy_onboarding_state.dart';

final class LazyOnboardingBloc extends Bloc<LazyOnboardingEvent, LazyOnboardingState> {
  final MindRepository _mindRepository;
  final SettingsRepository _settingsRepository;

  LazyOnboardingBloc({
    required MindRepository mindRepository,
    required SettingsRepository settingsRepository,
  })  : _mindRepository = mindRepository,
        _settingsRepository = settingsRepository,
        super(LazyOnboardingInitial()) {
    on<LazyOnboardingCheck>(_onCheck);
    on<LazyOnboardingCreate>(_onCreate);
    on<LazyOnboardingDelete>(_onDelete);
    on<LazyOnboardingMarkAsSeen>(_onMarkAsSeen);
    on<LazyOnboardingReset>(_onReset);
  }

  Future<void> _onCheck(
    LazyOnboardingCheck event,
    Emitter<LazyOnboardingState> emit,
  ) async {
    // If user has already seen onboarding, don't show it again
    if (_settingsRepository.value.hasSeenLazyOnboarding) {
      emit(LazyOnboardingNeeded(shouldShow: false));
      return;
    }

    // Get all minds
    final minds = await _mindRepository.obtainMinds();
    final totalMinds = minds.length;

    // Check conditions: totalMinds < 10 OR no minds in last 30 days
    final last30DaysMinds = MindUtils.findLast30DaysMinds(allMinds: minds.toList());
    final shouldShow = totalMinds < 10 || last30DaysMinds.isEmpty;

    emit(LazyOnboardingNeeded(shouldShow: shouldShow));
  }

  Future<void> _onCreate(
    LazyOnboardingCreate event,
    Emitter<LazyOnboardingState> emit,
  ) async {
    final todayDayIndex = kek_date_utils.DateUtils.getTodayIndex();
    final uuid = const Uuid();
    final l10n = event.context.l10n;

    final List<Mind> mindsToCreate = [];

    // Create parent minds with ONBOARDING_ prefix in ID
    for (final parentData in OnboardingConstants.parentMinds) {
      final parentId = '${OnboardingConstants.onboardingIdPrefix}${uuid.v4()}';
      final parentMind = Mind(
        id: parentId,
        emoji: parentData.emoji,
        note: parentData.translation(l10n),
        dayIndex: todayDayIndex,
        creationDate: DateTime.now(),
        sortIndex: parentData.sortIndex,
        rootId: null, // Parent minds have no rootId - they ARE the root
      );
      mindsToCreate.add(parentMind);

      // Create comment minds for this parent if they exist
      final commentTranslations = OnboardingConstants.commentMinds[parentData.sortIndex];
      if (commentTranslations != null) {
        for (int i = 0; i < commentTranslations.length; i++) {
          final commentMind = Mind(
            id: uuid.v4(),
            emoji: parentData.emoji,
            note: commentTranslations[i](l10n),
            dayIndex: todayDayIndex,
            creationDate: DateTime.now(),
            sortIndex: i,
            rootId: parentId, // Use parent's ID as rootId
          );
          mindsToCreate.add(commentMind);
        }
      }
    }

    // Create all minds in bulk
    await _mindRepository.createMinds(minds: mindsToCreate);

    emit(LazyOnboardingCreated());
  }

  Future<void> _onDelete(
    LazyOnboardingDelete event,
    Emitter<LazyOnboardingState> emit,
  ) async {
    // Delete all parent onboarding minds (those with ONBOARDING_ prefix)
    await _mindRepository.deleteMindsWhere(
      (mind) => OnboardingConstants.isOnboardingMindId(mind.id),
    );

    // Delete all comment minds (children of onboarding parent minds)
    final allMinds = await _mindRepository.obtainMinds();
    final onboardingParentIds = allMinds
        .where((mind) => OnboardingConstants.isOnboardingMindId(mind.id))
        .map((mind) => mind.id)
        .toSet();

    await _mindRepository.deleteMindsWhere(
      (mind) => mind.rootId != null && onboardingParentIds.contains(mind.rootId),
    );

    emit(LazyOnboardingDeleted());
  }

  Future<void> _onMarkAsSeen(
    LazyOnboardingMarkAsSeen event,
    Emitter<LazyOnboardingState> emit,
  ) async {
    final currentSettings = _settingsRepository.value;
    final updatedSettings = KeklistSettings(
      isMindContentVisible: currentSettings.isMindContentVisible,
      previousAppVersion: currentSettings.previousAppVersion,
      isDarkMode: currentSettings.isDarkMode,
      shouldShowTitles: currentSettings.shouldShowTitles,
      userName: currentSettings.userName,
      language: currentSettings.language,
      dataSchemaVersion: currentSettings.dataSchemaVersion,
      hasSeenLazyOnboarding: true,
      isDebugMenuVisible: currentSettings.isDebugMenuVisible,
    );

    await _settingsRepository.updateSettings(updatedSettings);
  }

  Future<void> _onReset(
    LazyOnboardingReset event,
    Emitter<LazyOnboardingState> emit,
  ) async {
    // Delete all existing onboarding minds first
    await _mindRepository.deleteMindsWhere(
      (mind) => OnboardingConstants.isOnboardingMindId(mind.id),
    );

    final allMinds = await _mindRepository.obtainMinds();
    final onboardingParentIds = allMinds
        .where((mind) => OnboardingConstants.isOnboardingMindId(mind.id))
        .map((mind) => mind.id)
        .toSet();

    await _mindRepository.deleteMindsWhere(
      (mind) => mind.rootId != null && onboardingParentIds.contains(mind.rootId),
    );

    // Reset the flag in settings
    final currentSettings = _settingsRepository.value;
    final updatedSettings = KeklistSettings(
      isMindContentVisible: currentSettings.isMindContentVisible,
      previousAppVersion: currentSettings.previousAppVersion,
      isDarkMode: currentSettings.isDarkMode,
      shouldShowTitles: currentSettings.shouldShowTitles,
      userName: currentSettings.userName,
      language: currentSettings.language,
      dataSchemaVersion: currentSettings.dataSchemaVersion,
      hasSeenLazyOnboarding: false,
      isDebugMenuVisible: currentSettings.isDebugMenuVisible,
    );

    await _settingsRepository.updateSettings(updatedSettings);

    emit(LazyOnboardingResetComplete());
  }
}
