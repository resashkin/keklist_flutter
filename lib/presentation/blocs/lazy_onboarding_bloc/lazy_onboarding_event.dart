part of 'lazy_onboarding_bloc.dart';

sealed class LazyOnboardingEvent extends Equatable {
  const LazyOnboardingEvent();

  @override
  List<Object?> get props => const [];
}

// Check if onboarding should be shown
final class LazyOnboardingCheck extends LazyOnboardingEvent {
  const LazyOnboardingCheck();
}

// Create onboarding minds
final class LazyOnboardingCreate extends LazyOnboardingEvent {
  final BuildContext context; // For translations

  const LazyOnboardingCreate({required this.context});

  @override
  List<Object?> get props => [context];
}

// Delete onboarding minds
final class LazyOnboardingDelete extends LazyOnboardingEvent {
  const LazyOnboardingDelete();
}

// Mark onboarding as seen (never show again)
final class LazyOnboardingMarkAsSeen extends LazyOnboardingEvent {
  const LazyOnboardingMarkAsSeen();
}

// Reset onboarding (for debugging/testing)
final class LazyOnboardingReset extends LazyOnboardingEvent {
  const LazyOnboardingReset();
}
