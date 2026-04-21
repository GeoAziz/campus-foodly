import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/order.dart';
import '../models/order_tracking_update.dart';
import '../repositories/order_tracking_repository.dart';

final orderTrackingRepositoryProvider = Provider<OrderTrackingRepository>(
  (ref) => OrderTrackingRepository(FirebaseFirestore.instance),
);

final orderTrackingStreamProvider =
    StreamProvider.family<OrderTrackingUpdate, String>((ref, orderId) {
  return ref.watch(orderTrackingRepositoryProvider).watchOrderTracking(orderId);
});

final orderByIdProvider =
    FutureProvider.family<Order?, String>((ref, orderId) async {
  final snapshot =
      await FirebaseFirestore.instance.collection('orders').doc(orderId).get();

  final data = snapshot.data();
  if (data == null) {
    return null;
  }

  return Order.fromMap(snapshot.id, data);
});

class PaymentSummary {
  const PaymentSummary({
    required this.provider,
    required this.status,
    required this.amount,
    required this.phoneNumber,
    required this.updatedAt,
  });

  final String provider;
  final String status;
  final double amount;
  final String phoneNumber;
  final DateTime updatedAt;
}

final paymentByOrderIdProvider =
    FutureProvider.family<PaymentSummary?, String>((ref, orderId) async {
  final query = await FirebaseFirestore.instance
      .collection('payments')
      .where('orderId', isEqualTo: orderId)
      .get();

  if (query.docs.isEmpty) {
    return null;
  }

  final docs = [...query.docs]..sort((a, b) {
      final aTime = _asDateTime(a.data()['updatedAt']);
      final bTime = _asDateTime(b.data()['updatedAt']);
      return bTime.compareTo(aTime);
    });

  final latest = docs.first.data();

  return PaymentSummary(
    provider: latest['provider'] as String? ?? 'unknown',
    status: latest['status'] as String? ?? 'pending',
    amount: (latest['amount'] as num? ?? 0).toDouble(),
    phoneNumber: latest['phoneNumber'] as String? ?? '',
    updatedAt: _asDateTime(latest['updatedAt']),
  );
});

DateTime _asDateTime(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return DateTime.now();
}
