part of 'debug_menu_bloc.dart';

sealed class DebugMenuEvent {
  const DebugMenuEvent();
}

final class DebugMenuGet extends DebugMenuEvent {}

final class DebugMenuUpdate extends DebugMenuEvent {
  final DebugMenuType flagType;
  final bool value;

  const DebugMenuUpdate({
    required this.flagType,
    required this.value,
  });
}

final class DebugMenuEnableDeveloperMode extends DebugMenuEvent {}
