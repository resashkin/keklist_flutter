part of 'mind_bloc.dart';

sealed class MindState {}

final class MindList extends MindState {
  final Iterable<Mind> values;

  MindList({required this.values});
}

final class MindMobileWidgetsUpdated extends MindState {}

final class MindSearching extends MindState {
  final bool enabled;
  final Iterable<Mind> allValues;
  final List<Mind> resultValues;

  MindSearching({
    required this.enabled,
    required this.allValues,
    required this.resultValues,
  });
}