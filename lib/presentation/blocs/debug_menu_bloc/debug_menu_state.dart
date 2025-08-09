part of 'debug_menu_bloc.dart';

sealed class DebugMenuState {}

final class DebugMenuDataState extends DebugMenuState {
  final List<DebugMenuData> debugMenuItems;
  final bool isDeveloperModeEnabled;

  DebugMenuDataState({
    required this.debugMenuItems,
    required this.isDeveloperModeEnabled,
  });
}

final class DebugMenuLoadingState extends DebugMenuState {
  final bool isLoading;

  DebugMenuLoadingState(this.isLoading);
}
