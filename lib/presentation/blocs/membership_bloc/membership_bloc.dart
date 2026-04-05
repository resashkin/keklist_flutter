import 'package:bloc/bloc.dart';
import 'package:keklist/domain/repositories/debug_menu/debug_menu_repository.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

part 'membership_event.dart';
part 'membership_state.dart';

final class MembershipBloc extends Bloc<MembershipEvent, MembershipState> {
  final DebugMenuRepository _debugMenuRepository;

  MembershipBloc({required DebugMenuRepository debugMenuRepository})
      : _debugMenuRepository = debugMenuRepository,
        super(MembershipInitialState()) {
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

    final bool isSimulating = _debugMenuRepository.value
            .where((item) => item.type == DebugMenuType.simulatePro)
            .firstOrNull
            ?.value ??
        false;

    if (isSimulating) {
      emit(MembershipDataState(
        isPro: true,
        nextRenewalDate: DateTime.now().add(const Duration(days: 30)),
        priceString: '\$2.99',
      ));
      return;
    }

    try {
      final CustomerInfo info = await Purchases.getCustomerInfo();
      final bool isPro = info.entitlements.active.isNotEmpty;

      if (!isPro) {
        emit(MembershipDataState(isPro: false));
        return;
      }

      final EntitlementInfo? entitlement = info.entitlements.active.values.firstOrNull;
      final DateTime? renewalDate = entitlement?.expirationDate != null
          ? DateTime.tryParse(entitlement!.expirationDate!)
          : null;
      final String? productId = entitlement?.productIdentifier;

      String? priceString;
      if (productId != null) {
        try {
          final List<StoreProduct> products = await Purchases.getProducts([productId]);
          priceString = products.firstOrNull?.priceString;
        } catch (_) {}
      }

      emit(MembershipDataState(isPro: true, nextRenewalDate: renewalDate, priceString: priceString));
    } catch (_) {
      emit(MembershipDataState(isPro: false));
    }
  }
}
