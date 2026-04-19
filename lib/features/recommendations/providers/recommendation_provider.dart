import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/restaurant.dart';
import '../../../data/providers/order_provider.dart';
import '../../../data/providers/restaurant_provider.dart';
import '../services/recommendation_service.dart';

final recommendationServiceProvider = Provider<RecommendationService>((ref) {
  return RecommendationService(
    orderRepository: ref.watch(orderRepositoryProvider),
    restaurantRepository: ref.watch(restaurantRepositoryProvider),
    firestore: FirebaseFirestore.instance,
  );
});

final forYouRecommendationsProvider =
    FutureProvider.family<List<Restaurant>, String>((ref, userId) {
  return ref
      .watch(recommendationServiceProvider)
      .recommendationsForUser(userId);
});
