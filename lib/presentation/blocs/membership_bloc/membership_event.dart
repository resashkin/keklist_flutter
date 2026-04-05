part of 'membership_bloc.dart';

sealed class MembershipEvent {
  const MembershipEvent();
}

final class MembershipGetEvent extends MembershipEvent {
  const MembershipGetEvent();
}

final class MembershipRefreshEvent extends MembershipEvent {
  const MembershipRefreshEvent();
}
