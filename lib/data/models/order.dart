import 'order_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp, FieldValue;

class Order {
  const Order({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.items,
    required this.status,
    required this.createdAt,
    required this.idempotencyKey,
    this.deliveryAddressId = '',
    this.deliveryAddressLabel = '',
    this.deliveryAddressLine = '',
  });

  final String id;
  final String userId;
  final String restaurantId;
  final List<OrderItem> items;
  final String status;
  final DateTime createdAt;
  final String idempotencyKey;
  final String deliveryAddressId;
  final String deliveryAddressLabel;
  final String deliveryAddressLine;

  double get totalAmount => items.fold(0, (sum, item) => sum + item.totalPrice);

  factory Order.fromMap(String id, Map<String, dynamic> data) {
    final createdAtValue = data['createdAt'];
    return Order(
      id: id,
      userId: data['userId'] as String? ?? '',
      restaurantId: data['restaurantId'] as String? ?? '',
      items: (data['items'] as List<dynamic>? ?? const [])
          .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList(growable: false),
      status: data['status'] as String? ?? 'pending',
      idempotencyKey: data['idempotencyKey'] as String? ?? '',
      deliveryAddressId: data['deliveryAddressId'] as String? ?? '',
      deliveryAddressLabel: data['deliveryAddressLabel'] as String? ?? '',
      deliveryAddressLine: data['deliveryAddressLine'] as String? ?? '',
      createdAt: createdAtValue is Timestamp
          ? createdAtValue.toDate()
          : createdAtValue is DateTime
              ? createdAtValue
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'restaurantId': restaurantId,
      'items': items.map((item) => item.toMap()).toList(growable: false),
      'status': status,
      'totalPrice': totalAmount,
      'idempotencyKey': idempotencyKey,
      'deliveryAddressId': deliveryAddressId,
      'deliveryAddressLabel': deliveryAddressLabel,
      'deliveryAddressLine': deliveryAddressLine,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
