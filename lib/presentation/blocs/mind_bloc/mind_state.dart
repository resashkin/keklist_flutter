part of 'mind_bloc.dart';

sealed class MindState extends Equatable {
  const MindState();

  @override
  List<Object?> get props => const [];
}

final class MindList extends MindState {
  final Iterable<Mind> values;

  const MindList({required this.values});

  @override
  List<Object?> get props => [values];
}

final class MindMobileWidgetsUpdated extends MindState {
  const MindMobileWidgetsUpdated();
}

final class MindSearching extends MindState {
  final bool enabled;
  final Iterable<Mind> allValues;
  final List<Mind> resultValues;

  const MindSearching({
    required this.enabled,
    required this.allValues,
    required this.resultValues,
  });

  @override
  List<Object?> get props => [enabled, allValues, resultValues];
}
