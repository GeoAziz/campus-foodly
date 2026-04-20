import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/restaurant.dart';
import '../repositories/restaurant_repository.dart';

final restaurantRepositoryProvider = Provider<RestaurantRepository>(
  (ref) => buildRestaurantRepository(),
);

final restaurantsProvider = FutureProvider<List<Restaurant>>(
  (ref) => ref.watch(restaurantRepositoryProvider).fetchRestaurants(),
);

const _maxFallbackFeaturedRestaurants = 5;
const _maxBestPickRestaurants = 5;

final featuredRestaurantsProvider =
    FutureProvider<List<Restaurant>>((ref) async {
  final restaurants = await ref.watch(restaurantsProvider.future);
  final featured = restaurants
      .where((restaurant) => restaurant.isFeatured)
      .toList(growable: false);

  // Keep featured sections usable when backend featured flags are missing.
  if (featured.isNotEmpty) {
    return featured;
  }

  developer.log(
    'No restaurants marked as featured. Using fallback top $_maxFallbackFeaturedRestaurants restaurants.',
    name: 'featuredRestaurantsProvider',
  );

  return restaurants
      .take(_maxFallbackFeaturedRestaurants)
      .toList(growable: false);
});

final bestPickRestaurantsProvider =
    FutureProvider<List<Restaurant>>((ref) async {
  final restaurants = await ref.watch(restaurantsProvider.future);

  if (restaurants.isEmpty) {
    return const <Restaurant>[];
  }

  final candidates = restaurants
      .where((restaurant) => !restaurant.isFeatured)
      .toList(growable: false);
  final source = candidates.isNotEmpty ? candidates : restaurants;

  final sorted = [...source]..sort((left, right) {
      final byRating = right.rating.compareTo(left.rating);
      if (byRating != 0) {
        return byRating;
      }

      return right.ratingCount.compareTo(left.ratingCount);
    });

  return sorted.take(_maxBestPickRestaurants).toList(growable: false);
});
