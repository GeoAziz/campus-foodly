import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/restaurant.dart';
import '../repositories/restaurant_repository.dart';

final restaurantRepositoryProvider = Provider<RestaurantRepository>(
  (ref) => buildRestaurantRepository(),
);

final restaurantsProvider = FutureProvider<List<Restaurant>>(
  (ref) => ref.watch(restaurantRepositoryProvider).fetchRestaurants(),
);

final featuredRestaurantsProvider =
    FutureProvider<List<Restaurant>>((ref) async {
  final restaurants = await ref.watch(restaurantsProvider.future);
  return restaurants
      .where((restaurant) => restaurant.isFeatured)
      .toList(growable: false);
});
