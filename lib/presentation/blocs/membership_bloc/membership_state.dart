part of 'membership_bloc.dart';

sealed class MembershipState extends Equatable {
  const MembershipState();

  @override
  List<Object?> get props => const [];
}

final class MembershipInitialState extends MembershipState {
  const MembershipInitialState();
}

final class MembershipLoadingState extends MembershipState {
  const MembershipLoadingState();
}

final class MembershipDataState extends MembershipState {
  final bool isPro;
  final DateTime? nextRenewalDate;
  final String? priceString;

  const MembershipDataState({
    required this.isPro,
    this.nextRenewalDate,
    this.priceString,
  });

  @override
  List<Object?> get props => [isPro, nextRenewalDate, priceString];
}
