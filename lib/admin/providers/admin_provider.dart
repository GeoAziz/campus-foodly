import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/order.dart';
import '../../data/models/order_item.dart';
import '../../data/models/restaurant.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/restaurant_repository.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/order_provider.dart';
import '../../data/providers/restaurant_provider.dart';

final adminAccessProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) {
    return false;
  }

  final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(user.id).get();
  return (userDoc.data()?['role'] as String? ?? '') == 'admin';
});

class AdminOperations {
  AdminOperations({
    required this.orderRepository,
    required this.restaurantRepository,
  });

  final OrderRepository orderRepository;
  final RestaurantRepository restaurantRepository;

  Future<List<Order>> fetchRecentOrders() {
    return orderRepository.fetchAllOrders(limit: 50);
  }

  Future<void> markOrderAsPreparing(Order order) =>
      orderRepository.updateOrderStatus(order.id, 'preparing');

  Future<List<Restaurant>> fetchRestaurants() {
    return restaurantRepository.fetchRestaurants();
  }

  Future<void> createRestaurant(String name, String location) async {
    await FirebaseFirestore.instance.collection('restaurants').add(
          Restaurant(
            id: '',
            name: name,
            image: '',
            location: location,
            rating: 4,
            deliveryTime: 30,
          ).toMap(),
        );
  }

  Future<void> seedDemoOrder(String userId) async {
    await orderRepository.saveOrder(
      Order(
        id: 'admin_seed_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        restaurantId: 'admin-managed',
        idempotencyKey: 'seed_${DateTime.now().millisecondsSinceEpoch}',
        items: const [
          OrderItem(
            id: 'item-1',
            name: 'Admin Test Item',
            quantity: 1,
            unitPrice: 1,
          ),
        ],
        status: 'pending',
        createdAt: DateTime.now(),
      ),
    );
  }
}

final adminOperationsProvider = Provider<AdminOperations>((ref) {
  return AdminOperations(
    orderRepository: ref.watch(orderRepositoryProvider),
    restaurantRepository: ref.watch(restaurantRepositoryProvider),
  );
});
