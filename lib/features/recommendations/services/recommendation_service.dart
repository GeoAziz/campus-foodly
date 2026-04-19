import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../../../data/models/order.dart';
import '../../../data/models/restaurant.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/restaurant_repository.dart';

class RecommendationService {
  RecommendationService({
    required OrderRepository orderRepository,
    required RestaurantRepository restaurantRepository,
    required FirebaseFirestore firestore,
  })  : _orderRepository = orderRepository,
        _restaurantRepository = restaurantRepository,
        _firestore = firestore;

  final OrderRepository _orderRepository;
  final RestaurantRepository _restaurantRepository;
  final FirebaseFirestore _firestore;

  Future<List<Restaurant>> recommendationsForUser(String userId) async {
    final orders = await _orderRepository.fetchOrdersForUser(userId);
    final allRestaurants = await _restaurantRepository.fetchRestaurants();

    final userDoc = await _firestore.collection('users').doc(userId).get();
    final preferredLocations =
        (userDoc.data()?['preferredLocations'] as List<dynamic>? ?? const [])
            .map((item) => item.toString().toLowerCase())
            .toSet();

    final orderCounts = <String, int>{};
    for (final Order order in orders) {
      orderCounts[order.restaurantId] =
          (orderCounts[order.restaurantId] ?? 0) + 1;
    }

    final scored = allRestaurants.map((restaurant) {
      final orderScore = orderCounts[restaurant.id] ?? 0;
      final locationScore =
          preferredLocations.contains(restaurant.location.toLowerCase())
              ? 2
              : 0;
      final ratingScore = restaurant.rating;
      final score = (orderScore * 3) + locationScore + ratingScore;
      return (restaurant: restaurant, score: score);
    }).toList(growable: false)
      ..sort((a, b) => b.score.compareTo(a.score));

    return scored
        .map((item) => item.restaurant)
        .take(5)
        .toList(growable: false);
  }
}
