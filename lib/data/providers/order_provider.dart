import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../repositories/order_repository.dart';
import '../services/order_validation_service.dart';
import '../services/idempotency_service.dart';

final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => buildOrderRepository(),
);

class OrderController extends StateNotifier<AsyncValue<List<Order>>> {
  OrderController(this._repository) : super(const AsyncValue.data([]));

  final OrderRepository _repository;
  final IdempotencyService _idempotencyService = IdempotencyService();
  
  // Track loaded user to prevent duplicate fetches on same user
  String? _loadedUserId;

  Future<void> loadForUser(String userId) async {
    // Prevent reloading if already loaded for this user
    if (_loadedUserId == userId) {
      debugPrint('[OrderController] Orders already loaded for user: $userId');
      return;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.fetchOrdersForUser(userId),
    );
    
    if (!state.hasError) {
      _loadedUserId = userId;
    }
  }

  Future<void> addOrder(Order order) async {
    await _repository.saveOrder(order);
    final current = state.value ?? <Order>[];
    state = AsyncValue.data([...current, order]);
  }

  /// Creates an Order from cart items with comprehensive validation and idempotency
  /// Returns the created Order with a unique ID
  Future<Order> createOrderFromCart({
    required String userId,
    required List<CartItem> cartItems,
    required double totalAmount,
    required String deliveryAddressId,
    required String deliveryAddressLabel,
    required String deliveryAddressLine,
  }) async {
    // 1. Validate order comprehensively
    final validation = OrderValidationService.validateOrder(
      cartItems: cartItems,
      checkoutAmount: totalAmount,
      deliveryAddressId: deliveryAddressId,
      deliveryAddressLine: deliveryAddressLine,
    );

    if (!validation.isValid) {
      throw StateError('Order validation failed: ${validation.errorMessage}');
    }

    // 2. Generate idempotency key to prevent duplicates
    const uuid = Uuid();
    final idempotencyKey = 'order_${uuid.v4()}';

    // 3. Check if this operation was already attempted
    if (_idempotencyService.isKeyValid(idempotencyKey)) {
      debugPrint('[OrderController] Duplicate order creation detected: $idempotencyKey');
      throw StateError('Order creation already in progress. Please wait.');
    }

    try {
      // Store the key to mark this operation as in-progress
      await _idempotencyService.storeKey(idempotencyKey);

      // Get restaurant ID from first item
      final restaurantId = cartItems.first.menuItem.restaurantId;

      // Convert CartItems to OrderItems
      final orderItems = cartItems
          .map(
            (cartItem) => OrderItem(
              id: cartItem.menuItem.id,
              name: cartItem.menuItem.name,
              quantity: cartItem.quantity,
              unitPrice: cartItem.menuItem.price,
            ),
          )
          .toList(growable: false);

      // Create new Order with unique ID (includes user ID to prevent collisions)
      final orderId =
          'order_${DateTime.now().millisecondsSinceEpoch}_${userId.hashCode}';
      final order = Order(
        id: orderId,
        userId: userId,
        restaurantId: restaurantId,
        items: orderItems,
        status: 'pending',
        deliveryAddressId: deliveryAddressId,
        deliveryAddressLabel: deliveryAddressLabel,
        deliveryAddressLine: deliveryAddressLine,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await _repository.saveOrder(order);

      // Update state
      final current = state.value ?? <Order>[];
      state = AsyncValue.data([...current, order]);

      debugPrint('[OrderController] Order created: ${order.id}');
      return order;
    } catch (e) {
      debugPrint('[OrderController] Error creating order: $e');
      // Remove the key if order creation failed
      await _idempotencyService.removeKey(idempotencyKey);
      rethrow;
    }
  }
}

final orderControllerProvider =
    StateNotifierProvider<OrderController, AsyncValue<List<Order>>>(
  (ref) => OrderController(ref.watch(orderRepositoryProvider)),
);
