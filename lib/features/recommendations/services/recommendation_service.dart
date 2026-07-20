import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:logger/logger.dart';

import '../../../data/models/order.dart';
import '../../../data/models/restaurant.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/restaurant_repository.dart';

final _logger = Logger();

/// Configuration for recommendation scoring
class RecommendationScoreConfig {
  const RecommendationScoreConfig({
    this.orderHistoryWeight = 3,
    this.locationWeight = 2,
    this.ratingWeight = 1,
    this.resultCount = 5,
  });

  /// Weight for order history score
  final int orderHistoryWeight;

  /// Weight for location preference score
  final int locationWeight;

  /// Weight for restaurant rating score
  final int ratingWeight;

  /// Number of recommendations to return
  final int resultCount;
}

/// Cached recommendation data
class _CachedRecommendations {
  _CachedRecommendations({
    required this.restaurants,
    required this.timestamp,
  });

  final List<Restaurant> restaurants;
  final DateTime timestamp;
}

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
  final Map<String, _CachedRecommendations> _cache = {};
  static const Duration _cacheDuration = Duration(hours: 1);

  RecommendationScoreConfig _scoreConfig = const RecommendationScoreConfig();

  /// Update recommendation scoring configuration
  void setScoreConfig(RecommendationScoreConfig config) {
    _scoreConfig = config;
    _logger.d(
      'RecommendationScoreConfig updated: '
      'history=${config.orderHistoryWeight}, '
      'location=${config.locationWeight}, '
      'rating=${config.ratingWeight}',
    );
  }

  /// Get recommendations for user with caching
  Future<List<Restaurant>> recommendationsForUser(
    String userId, {
    bool forceRefresh = false,
  }) async {
    try {
      // Check cache
      if (!forceRefresh && _cache.containsKey(userId)) {
        final cached = _cache[userId];
        if (cached != null &&
            DateTime.now().difference(cached.timestamp) < _cacheDuration) {
          _logger.d('[Recommendations] Using cached recommendations for $userId');
          return cached.restaurants;
        }
      }

      // Fetch fresh recommendations
      final recommendations = await _computeRecommendations(userId);

      // Cache results
      _cache[userId] = _CachedRecommendations(
        restaurants: recommendations,
        timestamp: DateTime.now(),
      );

      _logger.d(
        '[Recommendations] Generated ${recommendations.length} recommendations for $userId',
      );
      return recommendations;
    } catch (e) {
      _logger.e('[Recommendations] Error generating recommendations: $e');

      // Return cached recommendations on error if available
      final cached = _cache[userId];
      if (cached != null) {
        _logger.w('[Recommendations] Returning stale cached recommendations due to error');
        return cached.restaurants;
      }

      // Return empty list as fallback
      return [];
    }
  }

  /// Compute recommendations for user
  Future<List<Restaurant>> _computeRecommendations(String userId) async {
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
              ? _scoreConfig.locationWeight
              : 0;
      final ratingScore = restaurant.rating.toInt();
      final score = (orderScore * _scoreConfig.orderHistoryWeight) +
          locationScore +
          (ratingScore * _scoreConfig.ratingWeight);

      return (restaurant: restaurant, score: score);
    }).toList(growable: false)
      ..sort((a, b) => b.score.compareTo(a.score));

    return scored
        .map((item) => item.restaurant)
        .take(_scoreConfig.resultCount)
        .toList(growable: false);
  }

  /// Clear cache for user
  void clearCache(String userId) {
    _cache.remove(userId);
    _logger.d('[Recommendations] Cleared cache for $userId');
  }

  /// Clear all cached recommendations
  void clearAllCache() {
    _cache.clear();
    _logger.d('[Recommendations] Cleared all recommendation cache');
  }

  /// Get cache stats for debugging
  Map<String, dynamic> getCacheStats() {
    return {
      'cachedUsers': _cache.length,
      'userIds': _cache.keys.toList(),
    };
  }
}
