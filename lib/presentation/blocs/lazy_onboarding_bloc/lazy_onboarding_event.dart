part of 'lazy_onboarding_bloc.dart';

sealed class LazyOnboardingEvent {}

// Check if onboarding should be shown
final class LazyOnboardingCheck extends LazyOnboardingEvent {}

// Create onboarding minds
final class LazyOnboardingCreate extends LazyOnboardingEvent {
  final BuildContext context; // For translations

  LazyOnboardingCreate({required this.context});
}

// Delete onboarding minds
final class LazyOnboardingDelete extends LazyOnboardingEvent {}

// Mark onboarding as seen (never show again)
final class LazyOnboardingMarkAsSeen extends LazyOnboardingEvent {}

// Reset onboarding (for debugging/testing)
final class LazyOnboardingReset extends LazyOnboardingEvent {}
