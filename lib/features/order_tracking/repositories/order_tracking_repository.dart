import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../data/services/firebase_service.dart';
import '../models/order_tracking_update.dart';

class OrderTrackingRepository {
  OrderTrackingRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<OrderTrackingUpdate> watchOrderTracking(String orderId) {
    if (!FirebaseService.isInitialized) {
      return Stream<OrderTrackingUpdate>.error(
        StateError('Firebase is not initialized for order tracking.'),
      );
    }

    return _firestore
        .collection('order_tracking')
        .doc(orderId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        return OrderTrackingUpdate(
          orderId: orderId,
          status: 'pending',
          latitude: 0,
          longitude: 0,
          updatedAt: DateTime.now(),
        );
      }

      return OrderTrackingUpdate.fromMap(orderId, data);
    });
  }
}
