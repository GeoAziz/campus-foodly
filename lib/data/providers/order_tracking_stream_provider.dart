import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart';
import '../repositories/order_repository.dart';

/// Real-time order status updates using Firestore Stream
/// Listens to changes in a specific order and updates the UI in real-time
final orderStatusStreamProvider =
    StreamProvider.family<Order?, String>((ref, orderId) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('orders')
      .doc(orderId)
      .snapshots()
      .map((snapshot) {
        if (!snapshot.exists) {
          return null;
        }
        return Order.fromMap(snapshot.id, snapshot.data() as Map<String, dynamic>);
      })
      .handleError((error) {
        // Log error but keep stream open
        print('[OrderStatusStream] Error loading order status: $error');
        // Return null to indicate error state
        return null;
      });
});

/// Real-time tracking updates for active order
/// Provides order status, estimated delivery time, driver location updates
class OrderTrackingUpdate {
  const OrderTrackingUpdate({
    required this.orderId,
    required this.status,
    required this.estimatedDeliveryMinutes,
    required this.lastUpdated,
    this.driverLocation,
    this.driverName,
  });

  final String orderId;
  final String status;
  final int estimatedDeliveryMinutes;
  final DateTime lastUpdated;
  final Map<String, double>? driverLocation; // {lat, lng}
  final String? driverName;
}

/// Stream provider for order tracking updates
final orderTrackingStreamProvider =
    StreamProvider.family<OrderTrackingUpdate?, String>((ref, orderId) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('orders')
      .doc(orderId)
      .snapshots()
      .asyncMap((snapshot) async {
        if (!snapshot.exists) {
          return null;
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final status = data['status'] as String? ?? 'pending';
        final estimatedDelivery = data['estimatedDeliveryTime'] as int? ?? 0;
        final lastUpdated = (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now();

        // Get driver info if status is out_for_delivery
        String? driverName;
        Map<String, double>? driverLocation;

        if (status == 'out_for_delivery') {
          final driverId = data['driverId'] as String?;
          if (driverId != null) {
            try {
              final driverDoc = await firestore
                  .collection('drivers')
                  .doc(driverId)
                  .get();

              if (driverDoc.exists) {
                final driverData = driverDoc.data() as Map<String, dynamic>;
                driverName = driverData['name'] as String?;
                final location = driverData['lastLocation'] as Map<String, dynamic>?;
                if (location != null) {
                  driverLocation = {
                    'latitude': (location['latitude'] as num).toDouble(),
                    'longitude': (location['longitude'] as num).toDouble(),
                  };
                }
              }
            } catch (e) {
              print('[OrderTracking] Error loading driver info: $e');
            }
          }
        }

        return OrderTrackingUpdate(
          orderId: orderId,
          status: status,
          estimatedDeliveryMinutes: estimatedDelivery,
          lastUpdated: lastUpdated,
          driverLocation: driverLocation,
          driverName: driverName,
        );
      })
      .handleError((error) {
        print('[OrderTrackingStream] Error: $error');
        return null;
      });
});

/// Watch order status with automatic UI updates
/// Usage in UI:
/// ```dart
/// final orderTracking = ref.watch(orderTrackingStreamProvider(orderId));
/// orderTracking.when(
///   loading: () => LoadingWidget(),
///   error: (err, st) => ErrorWidget(),
///   data: (tracking) => TrackingWidget(tracking),
/// );
/// ```
