import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/mpesa_service.dart';

final mpesaServiceProvider = Provider<MpesaService>(
  (ref) => MpesaService(),
);

/// Payment state notifier for tracking payment progress
class PaymentStateNotifier extends StateNotifier<AsyncValue<MpesaPaymentStatus?>> {
  PaymentStateNotifier(this._mpesaService) : super(const AsyncValue.data(null));

  final MpesaService _mpesaService;

  /// Initiate STK Push and poll for payment
  Future<void> initiatePayment({
    required String phone,
    required int amount,
    required String orderId,
  }) async {
    state = const AsyncValue.loading();

    try {
      // Step 1: Initiate STK Push
      final checkoutRequestId = await _mpesaService.initiateStkPush(
        phone: phone,
        amount: amount,
        orderId: orderId,
      );

      // Step 2: Poll for payment status
      final status = await _mpesaService.pollPaymentStatus(
        checkoutRequestId: checkoutRequestId,
      );

      state = AsyncValue.data(status);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Query current payment status
  Future<void> queryPaymentStatus({
    required String checkoutRequestId,
  }) async {
    state = const AsyncValue.loading();

    try {
      final status = await _mpesaService.queryPaymentStatus(
        checkoutRequestId: checkoutRequestId,
      );
      state = AsyncValue.data(status);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final paymentStateProvider =
    StateNotifierProvider<PaymentStateNotifier, AsyncValue<MpesaPaymentStatus?>>(
  (ref) => PaymentStateNotifier(ref.watch(mpesaServiceProvider)),
);
