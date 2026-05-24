import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payment_status.dart';
import '../repositories/payment_repository.dart';

class PaymentState {
  const PaymentState({
    this.paymentId,
    this.status = PaymentStatus.idle,
    this.errorMessage,
    this.isSubmitting = false,
  });

  final String? paymentId;
  final PaymentStatus status;
  final String? errorMessage;
  final bool isSubmitting;

  PaymentState copyWith({
    String? paymentId,
    PaymentStatus? status,
    String? errorMessage,
    bool? isSubmitting,
  }) {
    return PaymentState(
      paymentId: paymentId ?? this.paymentId,
      status: status ?? this.status,
      errorMessage: errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => PaymentRepository(
    FirebaseFirestore.instance,
    // Use mock payment in debug mode for testing
    useMockPayment: kDebugMode,
    // Configure callback delay (default 3 seconds)
    mockPaymentDelay: const Duration(seconds: 3),
  ),
);

class PaymentController extends StateNotifier<PaymentState> {
  PaymentController(this._repository) : super(const PaymentState());

  final PaymentRepository _repository;
  StreamSubscription<PaymentStatus>? _statusSubscription;

  Future<void> startMpesaCheckout({
    required String orderId,
    required String userId,
    required String phoneNumber,
    required double amount,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      errorMessage: null,
      status: PaymentStatus.pending,
    );

    try {
      final paymentId = await _repository.requestMpesaPayment(
        orderId: orderId,
        userId: userId,
        phoneNumber: phoneNumber,
        amount: amount,
      );

      await _statusSubscription?.cancel();
      _statusSubscription =
          _repository.watchPaymentStatus(paymentId).listen((status) {
        state = state.copyWith(
          paymentId: paymentId,
          status: status,
          isSubmitting: false,
        );
      });

      state = state.copyWith(
        paymentId: paymentId,
        isSubmitting: false,
      );
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        status: PaymentStatus.failed,
        errorMessage: error.toString(),
      );
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }
}

final paymentControllerProvider =
    StateNotifierProvider.autoDispose<PaymentController, PaymentState>(
  (ref) => PaymentController(ref.watch(paymentRepositoryProvider)),
);
