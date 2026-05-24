import 'package:cloud_firestore/cloud_firestore.dart' as firebase hide Order;
import 'package:logger/logger.dart';

import '../models/order.dart';
import '../services/firebase_service.dart';
import '../services/idempotency_service.dart';
import '../services/connectivity_service.dart';

/// Extended order model with server-side validation fields
class OrderInput {
  final String userId;
  final String restaurantId;
  final List<Map<String, dynamic>> items;
  final double totalPrice;
  final double tax;
  final double deliveryFee;
  final String? couponCode;
  final String idempotencyKey;
  final String deliveryAddress;
  final String? specialInstructions;

  OrderInput({
    required this.userId,
    required this.restaurantId,
    required this.items,
    required this.totalPrice,
    required this.tax,
    required this.deliveryFee,
    required this.idempotencyKey,
    required this.deliveryAddress,
    this.couponCode,
    this.specialInstructions,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'restaurantId': restaurantId,
    'items': items,
    'totalPrice': totalPrice,
    'tax': tax,
    'deliveryFee': deliveryFee,
    'couponCode': couponCode,
    'idempotencyKey': idempotencyKey,
    'deliveryAddress': deliveryAddress,
    'specialInstructions': specialInstructions,
    'status': 'pending',
    'createdAt': FieldValue.serverTimestamp(),
  };
}

/// Pagination parameters for order queries
class OrderPaginationParams {
  final int pageSize;
  final DocumentSnapshot? startAfter;

  OrderPaginationParams({
    this.pageSize = 20,
    this.startAfter,
  });
}

/// Result of paginated order query
class OrderQueryResult {
  final List<Order> orders;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  OrderQueryResult({
    required this.orders,
    required this.lastDocument,
    required this.hasMore,
  });
}

abstract class OrderRepository {
  Future<List<Order>> fetchOrdersForUser(String userId);
  Future<OrderQueryResult> fetchOrdersForUserPaginated(
    String userId,
    OrderPaginationParams params,
  );
  Future<Order?> fetchOrderById(String orderId);
  Future<void> saveOrder(Order order);
  Future<void> createOrder(OrderInput orderInput);
  Future<void> updateOrderStatus(String orderId, String newStatus);
  Future<List<Order>> fetchOrdersByStatus(String status, {int limit = 50});
}

class FirestoreOrderRepository implements OrderRepository {
  FirestoreOrderRepository(this._firestore)
      : _logger = Logger(),
        _idempotencyService = IdempotencyService(),
        _connectivityService = ConnectivityService();

  final firebase.FirebaseFirestore _firestore;
  final Logger _logger;
  final IdempotencyService _idempotencyService;
  final ConnectivityService _connectivityService;

  @override
  Future<List<Order>> fetchOrdersForUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      _logger.i('Fetched ${snapshot.docs.length} orders for user: $userId');
      return snapshot.docs
          .map((doc) => Order.fromMap(doc.id, doc.data()))
          .toList(growable: false);
    } catch (e) {
      _logger.e('Error fetching orders for user: $e');
      rethrow;
    }
  }

  @override
  Future<OrderQueryResult> fetchOrdersForUserPaginated(
    String userId,
    OrderPaginationParams params,
  ) async {
    try {
      var query = _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(params.pageSize + 1); // Fetch one extra to determine if hasMore

      if (params.startAfter != null) {
        query = query.startAfterDocument(params.startAfter!);
      }

      final snapshot = await query.get();
      final hasMore = snapshot.docs.length > params.pageSize;
      final documents = hasMore
          ? snapshot.docs.sublist(0, params.pageSize)
          : snapshot.docs;

      final orders = documents
          .map((doc) => Order.fromMap(doc.id, doc.data()))
          .toList(growable: false);

      _logger.i('Fetched ${orders.length} orders (hasMore: $hasMore) for user: $userId');

      return OrderQueryResult(
        orders: orders,
        lastDocument: documents.isNotEmpty ? documents.last : null,
        hasMore: hasMore,
      );
    } catch (e) {
      _logger.e('Error fetching paginated orders: $e');
      rethrow;
    }
  }

  @override
  Future<Order?> fetchOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (!doc.exists) {
        _logger.w('Order not found: $orderId');
        return null;
      }
      return Order.fromMap(doc.id, doc.data()!);
    } catch (e) {
      _logger.e('Error fetching order: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveOrder(Order order) async {
    try {
      await _firestore
          .collection('orders')
          .doc(order.id)
          .set(order.toMap());
      _logger.i('Order saved: ${order.id}');
    } catch (e) {
      _logger.e('Error saving order: $e');
      rethrow;
    }
  }

  @override
  Future<void> createOrder(OrderInput orderInput) async {
    // Check connectivity first
    if (!_connectivityService.isOnline) {
      throw Exception('No internet connection. Please check your connection and try again.');
    }

    try {
      // Verify idempotency key hasn't been used
      if (_idempotencyService.hasKey(orderInput.idempotencyKey)) {
        _logger.w('Duplicate order attempt: ${orderInput.idempotencyKey}');
        throw Exception('This order has already been placed. Please refresh and try again.');
      }

      // Store idempotency key before attempting creation
      await _idempotencyService.storeKey(orderInput.idempotencyKey);

      // Create order with server-side validation
      final orderData = orderInput.toMap();
      final result = await _firestore
          .collection('orders')
          .add(orderData);

      _logger.i('Order created successfully: ${result.id}');
    } catch (e) {
      _logger.e('Error creating order: $e');
      // Remove idempotency key on failure to allow retry
      await _idempotencyService.removeKey(orderInput.idempotencyKey);
      rethrow;
    }
  }

  @override
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore
          .collection('orders')
          .doc(orderId)
          .update({
            'status': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      _logger.i('Order status updated: $orderId -> $newStatus');
    } catch (e) {
      _logger.e('Error updating order status: $e');
      rethrow;
    }
  }

  @override
  Future<List<Order>> fetchOrdersByStatus(String status, {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      _logger.i('Fetched ${snapshot.docs.length} orders with status: $status');
      return snapshot.docs
          .map((doc) => Order.fromMap(doc.id, doc.data()))
          .toList(growable: false);
    } catch (e) {
      _logger.e('Error fetching orders by status: $e');
      rethrow;
    }
  }
}

class InMemoryOrderRepository implements OrderRepository {
  final List<Order> _orders = [];
  final Logger _logger = Logger();

  @override
  Future<List<Order>> fetchOrdersForUser(String userId) async {
    return _orders.where((order) => order.userId == userId).toList();
  }

  @override
  Future<OrderQueryResult> fetchOrdersForUserPaginated(
    String userId,
    OrderPaginationParams params,
  ) async {
    final filtered = _orders.where((order) => order.userId == userId).toList();
    return OrderQueryResult(
      orders: filtered,
      lastDocument: null,
      hasMore: false,
    );
  }

  @override
  Future<Order?> fetchOrderById(String orderId) async {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveOrder(Order order) async {
    _orders.add(order);
    _logger.i('Order saved (in-memory): ${order.id}');
  }

  @override
  Future<void> createOrder(OrderInput orderInput) async {
    _logger.i('Order created (in-memory): ${orderInput.idempotencyKey}');
  }

  @override
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index >= 0) {
      _logger.i('Order status updated (in-memory): $orderId -> $newStatus');
    }
  }

  @override
  Future<List<Order>> fetchOrdersByStatus(String status, {int limit = 50}) async {
    return _orders.where((order) => order.status == status).take(limit).toList();
  }
}

OrderRepository buildOrderRepository() {
  if (!FirebaseService.isInitialized) {
    throw StateError(
      'Firebase is not initialized. Configure Firebase before using orders.',
    );
  }

  return FirestoreOrderRepository(firebase.FirebaseFirestore.instance);
}
