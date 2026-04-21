import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../repositories/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => buildOrderRepository(),
);

class OrderController extends StateNotifier<AsyncValue<List<Order>>> {
  OrderController(this._repository) : super(const AsyncValue.data([]));

  final OrderRepository _repository;

  Future<void> loadForUser(String userId) async {
    state = const AsyncValue.loading();
    state =
        await AsyncValue.guard(() => _repository.fetchOrdersForUser(userId));
  }

  Future<void> addOrder(Order order) async {
    await _repository.saveOrder(order);
    final current = state.value ?? <Order>[];
    state = AsyncValue.data([...current, order]);
  }

  /// Creates an Order from cart items
  /// Returns the created Order with a unique ID
  Future<Order> createOrderFromCart({
    required String userId,
    required List<CartItem> cartItems,
    required double totalAmount,
    required String deliveryAddressId,
    required String deliveryAddressLabel,
    required String deliveryAddressLine,
  }) async {
    if (cartItems.isEmpty) {
      throw StateError('Cannot create order from empty cart');
    }

    // Use first cart item's restaurant ID
    final restaurantId = cartItems.first.menuItem.restaurantId;

    // Verify all items are from the same restaurant
    if (!cartItems.every((item) => item.menuItem.restaurantId == restaurantId)) {
      throw StateError('All items must be from the same restaurant');
    }

    if (deliveryAddressId.isEmpty || deliveryAddressLine.isEmpty) {
      throw StateError('A delivery address is required before placing an order');
    }

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

    // Create new Order with unique ID
    final orderId = 'order_${DateTime.now().microsecondsSinceEpoch}_$userId';
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

    return order;
  }
}

final orderControllerProvider =
    StateNotifierProvider<OrderController, AsyncValue<List<Order>>>(
  (ref) => OrderController(ref.watch(orderRepositoryProvider)),
);
