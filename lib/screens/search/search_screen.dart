import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../components/cards/big/restaurant_info_big_card.dart';
import '../../components/skeleton/big_card_skeleton.dart';
import '../../core/constants.dart';
import '../../core/routes.dart';
import '../../data/models/restaurant.dart';
import '../../data/providers/filter_provider.dart';
import '../../data/providers/restaurant_provider.dart';
import '../../data/providers/ui_state_provider.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchUiControllerProvider);
    final filterState = ref.watch(restaurantFilterProvider);
    final restaurantsAsync = ref.watch(restaurantsProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: defaultPadding),
              Text('Search', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: defaultPadding),
              const SearchForm(),
              const SizedBox(height: defaultPadding),
              Text(
                  searchState.isSearching
                      ? 'Search Results'
                      : 'Top Restaurants',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: defaultPadding),
              Expanded(
                child: restaurantsAsync.when(
                  loading: () => ListView.builder(
                    itemCount: 3,
                    itemBuilder: (context, index) => const Padding(
                      padding: EdgeInsets.only(bottom: defaultPadding),
                      child: BigCardSkeleton(),
                    ),
                  ),
                  error: (error, stackTrace) => Center(
                    child: Text(
                      'Unable to load restaurants. ${error.toString()}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  data: (restaurants) {
                    final visibleRestaurants = _filteredRestaurants(
                      restaurants,
                      searchState.query,
                      filterState,
                    );

                    if (visibleRestaurants.isEmpty) {
                      return const Center(
                        child: Text('No restaurants found for your search.'),
                      );
                    }

                    return ListView.builder(
                      itemCount: visibleRestaurants.length,
                      itemBuilder: (context, index) {
                        final restaurant = visibleRestaurants[index];
                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: defaultPadding),
                          child: RestaurantInfoBigCard(
                            heroTag: 'search-${restaurant.id}',
                            images: [restaurant.image],
                            name: restaurant.name,
                            rating: restaurant.rating,
                            numOfRating: 200,
                            deliveryTime: restaurant.deliveryTime,
                            foodType: const ['Popular'],
                            press: () => context.pushNamed(
                              AppRoutes.details,
                              extra: restaurant,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<Restaurant> _filteredRestaurants(
  List<Restaurant> restaurants,
  String query,
  RestaurantFilterState filters,
) {
  final normalizedQuery = query.trim().toLowerCase();

  return restaurants.where((restaurant) {
    final matchesQuery = normalizedQuery.isEmpty ||
        restaurant.name.toLowerCase().contains(normalizedQuery) ||
        restaurant.location.toLowerCase().contains(normalizedQuery) ||
        restaurant.categories.any(
            (category) => category.toLowerCase().contains(normalizedQuery));

    final matchesCategory = filters.category == 'All' ||
        restaurant.categories.any(
          (category) =>
              category.toLowerCase() == filters.category.toLowerCase(),
        );

    final matchesDietary = filters.dietary == 'Any' ||
        restaurant.dietaries.any(
          (dietary) => dietary.toLowerCase() == filters.dietary.toLowerCase(),
        );

    final matchesPrice = restaurant.priceTier <= filters.maxPriceTier;
    final matchesRating = restaurant.rating >= filters.minRating;

    return matchesQuery &&
        matchesCategory &&
        matchesDietary &&
        matchesPrice &&
        matchesRating;
  }).toList(growable: false);
}

class SearchForm extends ConsumerStatefulWidget {
  const SearchForm({super.key});

  @override
  ConsumerState<SearchForm> createState() => _SearchFormState();
}

class _SearchFormState extends ConsumerState<SearchForm> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      onChanged: (value) =>
          ref.read(searchUiControllerProvider.notifier).updateQuery(value),
      onFieldSubmitted: (value) =>
          ref.read(searchUiControllerProvider.notifier).updateQuery(value),
      style: Theme.of(context).textTheme.labelLarge,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search OrderEats restaurants',
        contentPadding: kTextFieldPadding,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SvgPicture.asset(
            'assets/icons/search.svg',
            colorFilter: const ColorFilter.mode(
              bodyTextColor,
              BlendMode.srcIn,
            ),
          ),
        ),
        suffixIcon: IconButton(
          onPressed: () {
            _controller.clear();
            ref.read(searchUiControllerProvider.notifier).clearSearch();
          },
          icon: const Icon(Icons.close),
        ),
      ),
    );
  }
}
