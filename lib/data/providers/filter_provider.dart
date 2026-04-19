import 'package:flutter_riverpod/flutter_riverpod.dart';

class RestaurantFilterState {
  const RestaurantFilterState({
    this.category = 'All',
    this.dietary = 'Any',
    this.maxPriceTier = 5,
    this.minRating = 0,
  });

  final String category;
  final String dietary;
  final int maxPriceTier;
  final double minRating;

  RestaurantFilterState copyWith({
    String? category,
    String? dietary,
    int? maxPriceTier,
    double? minRating,
  }) {
    return RestaurantFilterState(
      category: category ?? this.category,
      dietary: dietary ?? this.dietary,
      maxPriceTier: maxPriceTier ?? this.maxPriceTier,
      minRating: minRating ?? this.minRating,
    );
  }
}

class RestaurantFilterController extends StateNotifier<RestaurantFilterState> {
  RestaurantFilterController() : super(const RestaurantFilterState());

  void setCategory(String category) {
    state = state.copyWith(category: category);
  }

  void setDietary(String dietary) {
    state = state.copyWith(dietary: dietary);
  }

  void setPriceTier(int tier) {
    state = state.copyWith(maxPriceTier: tier);
  }

  void setMinRating(double rating) {
    state = state.copyWith(minRating: rating);
  }

  void reset() {
    state = const RestaurantFilterState();
  }
}

final restaurantFilterProvider =
    StateNotifierProvider<RestaurantFilterController, RestaurantFilterState>(
  (ref) => RestaurantFilterController(),
);
