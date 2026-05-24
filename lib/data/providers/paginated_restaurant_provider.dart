import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/restaurant.dart';
import '../repositories/restaurant_repository.dart';

const int _pageSize = 10;

/// Pagination state for restaurant listing
class PaginationState {
  const PaginationState({
    this.items = const [],
    this.isLoading = false,
    this.hasMoreItems = true,
    this.error,
    this.currentPage = 0,
  });

  final List<Restaurant> items;
  final bool isLoading;
  final bool hasMoreItems;
  final String? error;
  final int currentPage;

  PaginationState copyWith({
    List<Restaurant>? items,
    bool? isLoading,
    bool? hasMoreItems,
    String? error,
    int? currentPage,
  }) {
    return PaginationState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMoreItems: hasMoreItems ?? this.hasMoreItems,
      error: error,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

final restaurantRepositoryProvider = Provider<RestaurantRepository>(
  (ref) => buildRestaurantRepository(),
);

/// Paginated restaurants provider with load-more capability
final paginatedRestaurantsProvider =
    StateNotifierProvider<PaginatedRestaurantsController, PaginationState>(
  (ref) => PaginatedRestaurantsController(ref.watch(restaurantRepositoryProvider)),
);

class PaginatedRestaurantsController extends StateNotifier<PaginationState> {
  PaginatedRestaurantsController(this._repository)
      : super(const PaginationState());

  final RestaurantRepository _repository;

  /// Load first page of restaurants
  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, error: null, currentPage: 0);
    try {
      final restaurants =
          await _repository.fetchRestaurantsPage(pageNumber: 0, pageSize: _pageSize);
      state = state.copyWith(
        items: restaurants,
        isLoading: false,
        hasMoreItems: restaurants.length == _pageSize,
        currentPage: 0,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load restaurants',
      );
    }
  }

  /// Load next page of restaurants (append to existing items)
  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMoreItems) return;

    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.currentPage + 1;
      final restaurants = await _repository.fetchRestaurantsPage(
        pageNumber: nextPage,
        pageSize: _pageSize,
      );

      state = state.copyWith(
        items: [...state.items, ...restaurants],
        isLoading: false,
        hasMoreItems: restaurants.length == _pageSize,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load more restaurants',
      );
    }
  }

  /// Refresh and reload from first page
  Future<void> refresh() async {
    await loadFirstPage();
  }
}

/// Keep the original non-paginated provider for featured/best-pick sections
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

  if (featured.isNotEmpty) {
    return featured;
  }

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
