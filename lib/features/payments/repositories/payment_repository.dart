import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../../../data/services/firebase_service.dart';
import '../../../data/services/mock_payment_service.dart';
import '../models/payment_status.dart';

class PaymentRepository {
  PaymentRepository(
    this._firestore, {
    this.useMockPayment = false,
    this.mockPaymentDelay = const Duration(seconds: 3),
  });

  final FirebaseFirestore _firestore;
  final bool useMockPayment;
  final Duration mockPaymentDelay;
  static const String _mpesaBackendUrl =
      String.fromEnvironment('MPESA_BACKEND_URL');

  Future<String> requestMpesaPayment({
    required String orderId,
    required String userId,
    required String phoneNumber,
    required double amount,
    bool? overrideMockPayment,
  }) async {
    if (!FirebaseService.isInitialized) {
      throw StateError('Firebase is not initialized for payments.');
    }

    // Use mock payment in dev mode or when explicitly enabled
    final shouldMock = overrideMockPayment ?? (useMockPayment || kDebugMode);

    if (shouldMock) {
      final mockService = MockPaymentService(_firestore);
      return await mockService.processPayment(
        orderId: orderId,
        userId: userId,
        phoneNumber: phoneNumber,
        amount: amount,
        shouldSucceed: true,
        callbackDelay: mockPaymentDelay,
      );
    }

    // Real M-Pesa implementation
    if (_mpesaBackendUrl.isEmpty) {
      throw StateError(
        'MPESA_BACKEND_URL is not configured. Provide your deployed functions URL using --dart-define.',
      );
    }

    final paymentId =
        'pay_${DateTime.now().microsecondsSinceEpoch}_${orderId.replaceAll(' ', '_')}';

    final backendUri = Uri.parse('$_mpesaBackendUrl/mpesa/stkpush');
    final response = await http.post(
      backendUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'paymentId': paymentId,
        'orderId': orderId,
        'userId': userId,
        'phoneNumber': phoneNumber,
        'amount': amount,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'M-Pesa STK push failed (${response.statusCode}): ${response.body}',
      );
    }

    final responseMap = jsonDecode(response.body) as Map<String, dynamic>;
    final checkoutRequestId =
        (responseMap['checkoutRequestId'] as String?) ?? paymentId;
    final paymentStatus = (responseMap['status'] as String?) ??
        paymentStatusToString(PaymentStatus.pending);

    await _firestore.collection('payments').doc(paymentId).set({
      'paymentId': paymentId,
      'checkoutRequestId': checkoutRequestId,
      'orderId': orderId,
      'userId': userId,
      'provider': 'mpesa',
      'phoneNumber': phoneNumber,
      'amount': amount,
      'status': paymentStatus,
      'handledByServer': true,
      'stkPushResponse': responseMap,
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
      'callbackPayload': null,
      'isMocked': false,
    });

    return paymentId;
  }

  Stream<PaymentStatus> watchPaymentStatus(String paymentId) {
    return _firestore
        .collection('payments')
        .doc(paymentId)
        .snapshots()
        .map((doc) {
      final data = doc.data();
      if (data == null) {
        return PaymentStatus.idle;
      }

      return paymentStatusFromString((data['status'] as String?) ?? 'idle');
    });
  }

  /// Updates the orderId in a payment record
  Future<void> linkOrderToPayment(String paymentId, String orderId) async {
    await _firestore.collection('payments').doc(paymentId).update({
      'orderId': orderId,
      'updatedAt': DateTime.now(),
    });
  }
}
