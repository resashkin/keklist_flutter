part of 'debug_menu_bloc.dart';

sealed class DebugMenuEvent extends Equatable {
  const DebugMenuEvent();

  @override
  List<Object?> get props => const [];
}

final class DebugMenuGet extends DebugMenuEvent {
  const DebugMenuGet();
}

final class DebugMenuUpdate extends DebugMenuEvent {
  final DebugMenuType flagType;
  final bool value;

  const DebugMenuUpdate({
    required this.flagType,
    required this.value,
  });

  @override
  List<Object?> get props => [flagType, value];
}

final class DebugMenuEnableDeveloperMode extends DebugMenuEvent {
  const DebugMenuEnableDeveloperMode();
}
