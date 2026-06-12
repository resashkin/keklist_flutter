import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
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
    } catch (e, stack) {
      debugPrint('[RevenueCat] error: $e');
      _sendToTelegram('🔴 RevenueCat error\n\n$e\n\n$stack');
      emit(MembershipDataState(isPro: false));
    }
  }

  Future<void> _sendToTelegram(String message) async {
    final token = dotenv.env['TELEGRAM_BOT_TOKEN'];
    final chatId = dotenv.env['TELEGRAM_CHAT_ID'];
    if (token == null || chatId == null) return;
    try {
      await http.post(
        Uri.parse('https://api.telegram.org/bot$token/sendMessage'),
        body: {
          'chat_id': chatId,
          'text': message.substring(0, min(4096, message.length)),
        },
      );
    } catch (_) {}
  }
}
