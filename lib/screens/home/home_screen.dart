import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../components/cards/big/big_card_image_slide.dart';
import '../../components/cards/big/restaurant_info_big_card.dart';
import '../../components/section_title.dart';
import '../../core/constants.dart';
import '../../core/routes.dart';
import '../../data/providers/location_provider.dart';
import '../../data/providers/campus_provider.dart';
import '../../data/providers/restaurant_provider.dart';
import '../../features/recommendations/presentation/for_you_section.dart';
import 'components/medium_card_list.dart';
import 'components/promotion_banner.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantsAsync = ref.watch(restaurantsProvider);
    final selectedCampusAsync = ref.watch(selectedCampusProvider);
    final locationLabel = selectedCampusAsync.maybeWhen(
      data: (campus) => campus?.name ?? 'Select Campus',
      orElse: () => ref.watch(selectedLocationProvider).valueOrNull ?? 'Choose location',
    );

    Future<void> refreshHome() async {
      try {
        await ref.refresh(restaurantsProvider.future).then((_) {});
      } catch (_) {}
    }

    Widget buildCenteredState(Widget child) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: child),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const SizedBox(),
        leadingWidth: 0,
        title: TextButton(
          onPressed: () => context.pushNamed(AppRoutes.campusSelector),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ordering from'.toUpperCase(),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(color: primaryColor),
              ),
              Text(
                locationLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
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
        child: RefreshIndicator(
          onRefresh: refreshHome,
          child: restaurantsAsync.when(
            loading: () =>
                buildCenteredState(const CircularProgressIndicator()),
            error: (error, stackTrace) => buildCenteredState(
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Unable to load home data: ${error.toString()}'),
                  TextButton(
                    onPressed: () => ref.invalidate(restaurantsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (restaurants) {
              final heroImages = restaurants.isEmpty
                  ? const <String>[]
                  : restaurants.map((restaurant) => restaurant.image).toList();

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(
                      child: SizedBox(height: defaultPadding)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: defaultPadding,
                      ),
                      child: BigCardImageSlide(
                        heroTag:
                            heroImages.isNotEmpty ? 'home-hero-main' : null,
                        images: heroImages.isNotEmpty
                            ? heroImages
                            : const [
                                'assets/images/big_1.png',
                                'assets/images/big_2.png',
                              ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: defaultPadding * 2),
                  ),
                  SliverToBoxAdapter(
                    child: SectionTitle(
                      title: 'Featured Partners',
                      press: () => context.pushNamed(AppRoutes.featured),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: defaultPadding),
                  ),
                  const SliverToBoxAdapter(
                    child: MediumCardList(
                      heroTagPrefix: 'home-featured',
                      listType: MediumCardListType.featured,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  const SliverToBoxAdapter(child: PromotionBanner()),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  SliverToBoxAdapter(
                    child: SectionTitle(
                      title: 'Best Pick',
                      press: () => context.pushNamed(AppRoutes.featured),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  const SliverToBoxAdapter(
                    child: MediumCardList(
                      heroTagPrefix: 'home-best-pick',
                      listType: MediumCardListType.bestPick,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  const SliverToBoxAdapter(child: ForYouSection()),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  const SliverToBoxAdapter(
                    child: SectionTitle(
                      title: 'All Restaurants',
                      showAction: false,
                      press: _noop,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final restaurant = restaurants[index];
                        return Padding(
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
                      childCount: restaurants.length,
                    ),
                  ),
                  const SliverToBoxAdapter(
                      child: SizedBox(height: defaultPadding)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

void _noop() {}
