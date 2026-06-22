part of 'mind_creator_bloc.dart';

final class MindCreatorState extends Equatable {
  final Iterable<String> suggestions;

  const MindCreatorState({required this.suggestions});

  @override
  List<Object?> get props => [suggestions];
}
