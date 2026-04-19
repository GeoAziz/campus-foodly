import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/cards/big/restaurant_info_big_card.dart';
import '../../../components/skeleton/big_card_skeleton.dart';
import '../../../core/constants.dart';
import '../../../core/routes.dart';

import '../../../data/providers/restaurant_provider.dart';

class Body extends ConsumerWidget {
  const Body({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantsAsync = ref.watch(featuredRestaurantsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
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
                'Unable to load featured restaurants: ${error.toString()}'),
          ),
          data: (restaurants) {
            if (restaurants.isEmpty) {
              return const Center(
                child: Text('No featured partners are configured yet.'),
              );
            }

            return ListView.builder(
              itemCount: restaurants.length,
              itemBuilder: (context, index) {
                final restaurant = restaurants[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: defaultPadding),
                  child: RestaurantInfoBigCard(
                    heroTag: 'featured-${restaurant.id}',
                    images: [restaurant.image],
                    name: restaurant.name,
                    rating: restaurant.rating,
                    numOfRating: restaurant.ratingCount,
                    deliveryTime: restaurant.deliveryTime,
                    foodType: restaurant.categories.isEmpty
                        ? const ['Popular']
                        : restaurant.categories,
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
    );
  }
}
