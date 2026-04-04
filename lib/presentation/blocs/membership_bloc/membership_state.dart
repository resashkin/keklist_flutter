part of 'membership_bloc.dart';

sealed class MembershipState {}

final class MembershipInitialState extends MembershipState {}

final class MembershipLoadingState extends MembershipState {}

final class MembershipDataState extends MembershipState {
  final bool isPro;

  MembershipDataState({required this.isPro});
}
