import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

enum OrderTrackingStage {
  pending,
  preparing,
  outForDelivery,
  delivered,
  unknown,
}

class OrderTrackingUpdate {
  const OrderTrackingUpdate({
    required this.orderId,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
  });

  final String orderId;
  final String status;
  final double latitude;
  final double longitude;
  final DateTime updatedAt;

  OrderTrackingStage get stage {
    final normalizedStatus = status.toLowerCase().replaceAll(' ', '_');
    switch (normalizedStatus) {
      case 'pending':
      case 'placed':
      case 'confirmed':
        return OrderTrackingStage.pending;
      case 'preparing':
      case 'processing':
      case 'cooking':
        return OrderTrackingStage.preparing;
      case 'out_for_delivery':
      case 'on_the_way':
      case 'on_the_way_to_you':
        return OrderTrackingStage.outForDelivery;
      case 'delivered':
      case 'completed':
        return OrderTrackingStage.delivered;
      default:
        return OrderTrackingStage.unknown;
    }
  }

  String get statusLabel {
    switch (stage) {
      case OrderTrackingStage.pending:
        return 'Order received';
      case OrderTrackingStage.preparing:
        return 'Preparing your meal';
      case OrderTrackingStage.outForDelivery:
        return 'On the way';
      case OrderTrackingStage.delivered:
        return 'Delivered';
      case OrderTrackingStage.unknown:
        return status
            .replaceAll('_', ' ')
            .split(' ')
            .where((part) => part.isNotEmpty)
            .map((part) => part[0].toUpperCase() + part.substring(1))
            .join(' ');
    }
  }

  String get statusDescription {
    switch (stage) {
      case OrderTrackingStage.pending:
        return 'We have received your order and are getting things ready.';
      case OrderTrackingStage.preparing:
        return 'The kitchen is working on your order right now.';
      case OrderTrackingStage.outForDelivery:
        return 'Your order is out for delivery and moving toward you.';
      case OrderTrackingStage.delivered:
        return 'Your order has been delivered successfully.';
      case OrderTrackingStage.unknown:
        return 'We are tracking your order and will update this screen as it changes.';
    }
  }

  bool get hasLocation => latitude != 0 || longitude != 0;

  bool get hasLiveMovement => stage == OrderTrackingStage.outForDelivery;

  factory OrderTrackingUpdate.fromMap(
      String orderId, Map<String, dynamic> map) {
    final updatedAtValue = map['updatedAt'];
    return OrderTrackingUpdate(
      orderId: orderId,
      status: map['status'] as String? ?? 'pending',
      latitude: (map['latitude'] as num? ?? 0).toDouble(),
      longitude: (map['longitude'] as num? ?? 0).toDouble(),
      updatedAt: updatedAtValue is Timestamp
          ? updatedAtValue.toDate()
          : updatedAtValue is DateTime
              ? updatedAtValue
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'updatedAt': updatedAt,
    };
  }
}
