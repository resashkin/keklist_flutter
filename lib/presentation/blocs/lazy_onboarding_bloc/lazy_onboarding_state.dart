part of 'lazy_onboarding_bloc.dart';

sealed class LazyOnboardingState extends Equatable {
  @override
  List<Object?> get props => [];
}

final class LazyOnboardingInitial extends LazyOnboardingState {}

final class LazyOnboardingNeeded extends LazyOnboardingState {
  final bool shouldShow;

  LazyOnboardingNeeded({required this.shouldShow});

  @override
  List<Object?> get props => [shouldShow];
}

final class LazyOnboardingCreated extends LazyOnboardingState {}

final class LazyOnboardingDeleted extends LazyOnboardingState {}

final class LazyOnboardingResetComplete extends LazyOnboardingState {}
