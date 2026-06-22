part of 'debug_menu_bloc.dart';

sealed class DebugMenuState extends Equatable {
  const DebugMenuState();

  @override
  List<Object?> get props => const [];
}

final class DebugMenuDataState extends DebugMenuState {
  final List<DebugMenuData> debugMenuItems;
  final bool isDeveloperModeEnabled;

  const DebugMenuDataState({
    required this.debugMenuItems,
    required this.isDeveloperModeEnabled,
  });

  @override
  List<Object?> get props => [debugMenuItems, isDeveloperModeEnabled];
}

final class DebugMenuLoadingState extends DebugMenuState {
  final bool isLoading;

  const DebugMenuLoadingState(this.isLoading);

  @override
  List<Object?> get props => [isLoading];
}
