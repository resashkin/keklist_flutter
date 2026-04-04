import 'package:bloc/bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

part 'membership_event.dart';
part 'membership_state.dart';

final class MembershipBloc extends Bloc<MembershipEvent, MembershipState> {
  MembershipBloc() : super(MembershipInitialState()) {
    on<MembershipGetEvent>(_onGet);
    on<MembershipRefreshEvent>(_onRefresh);
  }

  Future<void> _onGet(MembershipGetEvent event, Emitter<MembershipState> emit) async {
    await _fetchAndEmit(emit);
  }

  Future<void> _onRefresh(MembershipRefreshEvent event, Emitter<MembershipState> emit) async {
    await _fetchAndEmit(emit);
  }

  Future<void> _fetchAndEmit(Emitter<MembershipState> emit) async {
    emit(MembershipLoadingState());
    try {
      final CustomerInfo info = await Purchases.getCustomerInfo();
      emit(MembershipDataState(isPro: info.entitlements.active.isNotEmpty));
    } catch (_) {
      emit(MembershipDataState(isPro: false));
    }
  }
}
