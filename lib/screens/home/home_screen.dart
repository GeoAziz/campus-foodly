import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../components/cards/big/big_card_image_slide.dart';
import '../../components/cards/big/restaurant_info_big_card.dart';
import '../../components/section_title.dart';
import '../../core/constants.dart';
import '../../core/routes.dart';
import '../../data/providers/restaurant_provider.dart';
import '../../features/recommendations/presentation/for_you_section.dart';
import 'components/medium_card_list.dart';
import 'components/promotion_banner.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantsAsync = ref.watch(restaurantsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const SizedBox(),
        title: Column(
          children: [
            Text(
              "Delivery to".toUpperCase(),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(color: primaryColor),
            ),
            const Text(
              "San Francisco",
              style: TextStyle(color: Colors.black),
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.pushNamed(AppRoutes.filter);
            },
            child: Text(
              "Filter",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: restaurantsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Unable to load home data: ${error.toString()}'),
          ),
          data: (restaurants) {
            final heroImages = restaurants.isEmpty
                ? const <String>[]
                : restaurants.map((restaurant) => restaurant.image).toList();

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: defaultPadding),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: defaultPadding),
                    child: BigCardImageSlide(
                      heroTag: heroImages.isNotEmpty ? 'home-hero-main' : null,
                      images: heroImages.isNotEmpty
                          ? heroImages
                          : const [
                              'assets/images/big_1.png',
                              'assets/images/big_2.png',
                            ],
                    ),
                  ),
                  const SizedBox(height: defaultPadding * 2),
                  SectionTitle(
                    title: "Featured Partners",
                    press: () => context.pushNamed(AppRoutes.featured),
                  ),
                  const SizedBox(height: defaultPadding),
                  const MediumCardList(
                    heroTagPrefix: 'home-featured',
                    showOnlyFeatured: true,
                  ),
                  const SizedBox(height: 20),
                  const PromotionBanner(),
                  const SizedBox(height: 20),
                  SectionTitle(
                    title: "Best Pick",
                    press: () => context.pushNamed(AppRoutes.featured),
                  ),
                  const SizedBox(height: 16),
                  const MediumCardList(
                    heroTagPrefix: 'home-best-pick',
                    showOnlyFeatured: true,
                  ),
                  const SizedBox(height: 20),
                  const ForYouSection(),
                  const SizedBox(height: 20),
                  SectionTitle(title: "All Restaurants", press: () {}),
                  const SizedBox(height: 16),
                  ...restaurants.map(
                    (restaurant) => Padding(
                      padding: const EdgeInsets.fromLTRB(
                        defaultPadding,
                        0,
                        defaultPadding,
                        defaultPadding,
                      ),
                      child: RestaurantInfoBigCard(
                        heroTag: 'home-all-${restaurant.id}',
                        images: [restaurant.image],
                        name: restaurant.name,
                        rating: restaurant.rating,
                        numOfRating: 200,
                        deliveryTime: restaurant.deliveryTime,
                        foodType: const ["Popular"],
                        press: () => context.pushNamed(
                          AppRoutes.details,
                          extra: restaurant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
