import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

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
