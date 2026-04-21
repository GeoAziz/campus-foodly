import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

/// Mock M-Pesa Payment Service for Development
/// Simulates the complete M-Pesa STK push and callback flow
class MockPaymentService {
  MockPaymentService(this._firestore);

  final FirebaseFirestore _firestore;

  /// Simulates M-Pesa STK push request
  /// Returns a mock response with checkoutRequestId
  Future<Map<String, dynamic>> simulateStkPush({
    required String paymentId,
    required String orderId,
    required String userId,
    required String phoneNumber,
    required double amount,
  }) async {
    // Generate mock M-Pesa response
    final checkoutRequestId = _generateCheckoutRequestId();
    final merchantRequestId = _generateMerchantRequestId();

    return {
      'checkoutRequestId': checkoutRequestId,
      'merchantRequestId': merchantRequestId,
      'status': 'pending',
      'responseCode': '0',
      'responseDescription': 'Success. Request accepted for processing',
      'customerMessage': 'Success. Request accepted for processing',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Simulates the callback from M-Pesa
  /// Updates payment status in Firestore after a delay
  Future<void> simulatePaymentCallback({
    required String paymentId,
    required double amount,
    required String phoneNumber,
    bool shouldSucceed = true,
    Duration delay = const Duration(seconds: 3),
  }) async {
    // Wait to simulate real M-Pesa callback delay
    await Future.delayed(delay);

    final callbackTimestamp = DateTime.now();

    if (shouldSucceed) {
      // Simulate successful payment
      final mpesaReceiptNumber = _generateMpesaReceiptNumber();

      final callbackPayload = {
        'Body': {
          'stkCallback': {
            'MerchantCheckoutSessionID': paymentId,
            'CheckoutRequestID': paymentId,
            'ResultCode': 0,
            'ResultDesc': 'The service request has been processed successfully.',
            'CallbackMetadata': {
              'Item': [
                {'Name': 'Amount', 'Value': amount},
                {'Name': 'MpesaReceiptNumber', 'Value': mpesaReceiptNumber},
                {'Name': 'TransactionDate', 'Value': '20240420120000'},
                {'Name': 'PhoneNumber', 'Value': _formatPhoneNumber(phoneNumber)},
              ]
            }
          }
        }
      };

      // Update payment status to succeeded
      await _firestore.collection('payments').doc(paymentId).update({
        'status': 'succeeded',
        'callbackPayload': callbackPayload,
        'mpesaReceiptNumber': mpesaReceiptNumber,
        'transactionDate': callbackTimestamp,
        'updatedAt': callbackTimestamp,
        'isMocked': true,
      });

      // Also update the associated order status
      final paymentDoc = await _firestore.collection('payments').doc(paymentId).get();
      final orderId = paymentDoc['orderId'];
      if (orderId != null) {
        await _firestore.collection('orders').doc(orderId).update({
          'paymentStatus': 'succeeded',
          'paidAt': callbackTimestamp,
        });
      }
    } else {
      // Simulate failed payment
      final callbackPayload = {
        'Body': {
          'stkCallback': {
            'MerchantCheckoutSessionID': paymentId,
            'CheckoutRequestID': paymentId,
            'ResultCode': 1,
            'ResultDesc': 'The user cancelled the USSD menu while entering the PIN.',
          }
        }
      };

      await _firestore.collection('payments').doc(paymentId).update({
        'status': 'failed',
        'callbackPayload': callbackPayload,
        'failureReason': 'User cancelled transaction',
        'transactionDate': callbackTimestamp,
        'updatedAt': callbackTimestamp,
        'isMocked': true,
      });

      // Update order status to payment_failed
      final paymentDoc = await _firestore.collection('payments').doc(paymentId).get();
      final orderId = paymentDoc['orderId'];
      if (orderId != null) {
        await _firestore.collection('orders').doc(orderId).update({
          'paymentStatus': 'failed',
        });
      }
    }
  }

  /// Initiates both STK push and simulates callback
  /// Returns payment ID and optionally triggers callback after delay
  Future<String> processPayment({
    required String orderId,
    required String userId,
    required String phoneNumber,
    required double amount,
    bool shouldSucceed = true,
    Duration callbackDelay = const Duration(seconds: 3),
  }) async {
    final paymentId =
        'pay_${DateTime.now().microsecondsSinceEpoch}_${orderId.replaceAll(' ', '_')}';

    // Simulate STK push
    final stkResponse = await simulateStkPush(
      paymentId: paymentId,
      orderId: orderId,
      userId: userId,
      phoneNumber: phoneNumber,
      amount: amount,
    );

    // Save initial payment record
    await _firestore.collection('payments').doc(paymentId).set({
      'paymentId': paymentId,
      'checkoutRequestId': stkResponse['checkoutRequestId'],
      'orderId': orderId,
      'userId': userId,
      'provider': 'mpesa_mock',
      'phoneNumber': phoneNumber,
      'amount': amount,
      'status': 'pending',
      'handledByServer': false,
      'stkPushResponse': stkResponse,
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
      'callbackPayload': null,
      'isMocked': true,
    });

    // Simulate callback in background
    unawaited(simulatePaymentCallback(
      paymentId: paymentId,
      amount: amount,
      phoneNumber: phoneNumber,
      shouldSucceed: shouldSucceed,
      delay: callbackDelay,
    ));

    return paymentId;
  }

  /// Generates a mock M-Pesa checkout request ID
  String _generateCheckoutRequestId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(32, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// Generates a mock merchant request ID
  String _generateMerchantRequestId() {
    const chars = '0123456789';
    final random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// Generates a mock M-Pesa receipt number
  String _generateMpesaReceiptNumber() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(10, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// Formats phone number to M-Pesa format (254XXXXXXXXX)
  String _formatPhoneNumber(String phoneNumber) {
    // Remove any non-digit characters
    final cleaned = phoneNumber.replaceAll(RegExp(r'\D'), '');

    // If starts with 0, replace with 254
    if (cleaned.startsWith('0')) {
      return '254${cleaned.substring(1)}';
    }

    // If already has country code, return as is
    if (cleaned.startsWith('254')) {
      return cleaned;
    }

    // Otherwise prepend 254
    return '254$cleaned';
  }
}

// Extension to handle unawaited futures
extension UnawaiterExtension<T> on Future<T> {
  void unawaited() {}
}

// Helper function
void unawaited(Future<void> future) {
  future.ignore();
}
