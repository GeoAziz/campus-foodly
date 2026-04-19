import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/restaurant_detail.dart';
import '../repositories/restaurant_detail_repository.dart';

final restaurantDetailRepositoryProvider = Provider<RestaurantDetailRepository>(
  (ref) => buildRestaurantDetailRepository(),
);

final restaurantDetailProvider =
    FutureProvider.family<RestaurantDetail?, String>((ref, restaurantId) {
  return ref
      .watch(restaurantDetailRepositoryProvider)
      .fetchRestaurantDetail(restaurantId);
});