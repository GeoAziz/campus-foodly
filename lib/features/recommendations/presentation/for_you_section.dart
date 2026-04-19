import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/cards/big/restaurant_info_big_card.dart';
import '../../../components/section_title.dart';
import '../../../constants.dart';
import '../../../data/providers/auth_provider.dart';
import '../providers/recommendation_provider.dart';

class ForYouSection extends ConsumerWidget {
  const ForYouSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.valueOrNull;

    if (user == null) {
      return const SizedBox.shrink();
    }

    final recommendations = ref.watch(forYouRecommendationsProvider(user.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: 'For You', press: () {}),
        const SizedBox(height: defaultPadding),
        recommendations.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: defaultPadding),
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
            child: Text('Recommendations unavailable: ${error.toString()}'),
          ),
          data: (restaurants) {
            if (restaurants.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: defaultPadding),
                child: Text('No personalized recommendations yet.'),
              );
            }

            return Column(
              children: restaurants
                  .map(
                    (restaurant) => Padding(
                      padding: const EdgeInsets.fromLTRB(
                        defaultPadding,
                        0,
                        defaultPadding,
                        defaultPadding,
                      ),
                      child: RestaurantInfoBigCard(
                        images: [restaurant.image],
                        name: restaurant.name,
                        rating: restaurant.rating,
                        numOfRating: 200,
                        deliveryTime: restaurant.deliveryTime,
                        foodType: const ['Recommended'],
                        press: () {},
                      ),
                    ),
                  )
                  .toList(growable: false),
            );
          },
        ),
      ],
    );
  }
}
