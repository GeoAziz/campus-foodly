import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/cards/medium/restaurant_info_medium_card.dart';
import '../../../components/skeleton/medium_card_skeleton.dart';
import '../../../core/constants.dart';
import '../../../core/routes.dart';
import '../../../data/providers/restaurant_provider.dart';

enum MediumCardListType { all, featured, bestPick }

class MediumCardList extends ConsumerWidget {
  const MediumCardList({
    super.key,
    this.heroTagPrefix = 'medium',
    this.listType = MediumCardListType.all,
  });

  final String heroTagPrefix;
  final MediumCardListType listType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantsAsync = switch (listType) {
      MediumCardListType.featured => ref.watch(featuredRestaurantsProvider),
      MediumCardListType.bestPick => ref.watch(bestPickRestaurantsProvider),
      MediumCardListType.all => ref.watch(restaurantsProvider),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          height: 254,
          child: restaurantsAsync.when(
            loading: buildFeaturedPartnersLoadingIndicator,
            error: (error, stackTrace) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Unable to load restaurants: ${error.toString()}'),
                  TextButton(
                    onPressed: () => ref.invalidate(restaurantsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (restaurants) {
              if (restaurants.isEmpty) {
                return Center(
                  child: Text(
                    switch (listType) {
                      MediumCardListType.featured =>
                        'No featured partners available.',
                      MediumCardListType.bestPick =>
                        'No best picks available yet.',
                      MediumCardListType.all => 'No restaurants available.',
                    },
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: restaurants.length,
                itemBuilder: (context, index) {
                  final restaurant = restaurants[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      left: defaultPadding,
                      right: (restaurants.length - 1) == index
                          ? defaultPadding
                          : 0,
                    ),
                    child: RestaurantInfoMediumCard(
                      heroTag: '$heroTagPrefix-${restaurant.id}-$index',
                      image: restaurant.image,
                      name: restaurant.name,
                      location: restaurant.location,
                      deliveryTime: restaurant.deliveryTime,
                      rating: restaurant.rating,
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
    );
  }

  Widget buildFeaturedPartnersLoadingIndicator() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(
          2,
          (index) => const Padding(
            padding: EdgeInsets.only(left: defaultPadding),
            child: MediumCardSkeleton(),
          ),
        ),
      ),
    );
  }
}
