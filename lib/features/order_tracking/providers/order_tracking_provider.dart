import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order_tracking_update.dart';
import '../repositories/order_tracking_repository.dart';

final orderTrackingRepositoryProvider = Provider<OrderTrackingRepository>(
  (ref) => OrderTrackingRepository(FirebaseFirestore.instance),
);

final orderTrackingStreamProvider =
    StreamProvider.family<OrderTrackingUpdate, String>((ref, orderId) {
  return ref.watch(orderTrackingRepositoryProvider).watchOrderTracking(orderId);
});
