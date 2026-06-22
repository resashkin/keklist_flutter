part of 'membership_bloc.dart';

sealed class MembershipEvent extends Equatable {
  const MembershipEvent();

  @override
  List<Object?> get props => const [];
}

final class MembershipGetEvent extends MembershipEvent {
  const MembershipGetEvent();
}

final class MembershipRefreshEvent extends MembershipEvent {
  const MembershipRefreshEvent();
}
