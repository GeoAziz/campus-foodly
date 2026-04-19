import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentWebhookClient {
  PaymentWebhookClient(this._firestore);

  final FirebaseFirestore _firestore;

  Future<String> createPendingMpesaPayment({
    required String orderId,
    required String userId,
    required String phoneNumber,
    required double amount,
  }) async {
    final paymentId =
        'pay_${DateTime.now().microsecondsSinceEpoch}_${orderId.replaceAll(' ', '_')}';

    await _firestore.collection('payments').doc(paymentId).set({
      'paymentId': paymentId,
      'orderId': orderId,
      'userId': userId,
      'provider': 'mpesa',
      'phoneNumber': phoneNumber,
      'amount': amount,
      'status': 'pending',
      'handledByServer': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return paymentId;
  }
}
