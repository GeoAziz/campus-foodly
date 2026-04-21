import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/routes.dart';
import '../../data/models/restaurant.dart';
import '../../data/models/featured_item.dart';
import '../../data/models/menu_item.dart';
import '../../data/models/menu_tab.dart';
import '../../data/models/restaurant_detail.dart';
import '../../data/providers/featured_item_provider.dart';
import '../../data/providers/menu_provider.dart';
import '../../data/providers/menu_tab_provider.dart';
import '../../data/providers/restaurant_detail_provider.dart';
import 'components/featured_items.dart';
import 'components/items.dart';
import 'components/restaurant_info.dart';

class DetailsScreen extends ConsumerWidget {
  const DetailsScreen({super.key, this.restaurant});

  final Restaurant? restaurant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantId = restaurant?.id;
    final restaurantName = restaurant?.name ?? 'Restaurant Details';
    final restaurantRating = restaurant?.rating ?? 4.3;
    final restaurantCategories =
        restaurant?.categories ?? const ['Chinese', 'American', 'Deshi food'];
    final menuItemsAsync = restaurantId == null
        ? const AsyncValue<List<MenuItem>>.data([])
        : ref.watch(menuItemsProvider(restaurantId));
    final featuredItemsAsync = restaurantId == null
        ? const AsyncValue<List<FeaturedItem>>.data([])
        : ref.watch(featuredItemsProvider(restaurantId));
    final menuTabsAsync = restaurantId == null
        ? const AsyncValue<List<MenuTabItem>>.data([])
        : ref.watch(menuTabsProvider(restaurantId));
    final restaurantDetailAsync = restaurantId == null
        ? const AsyncValue<RestaurantDetail?>.data(null)
        : ref.watch(restaurantDetailProvider(restaurantId));

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: SvgPicture.asset("assets/icons/share.svg"),
            onPressed: () {},
          ),
          IconButton(
            icon: SvgPicture.asset("assets/icons/search.svg"),
            onPressed: () => context.pushNamed(AppRoutes.search),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: defaultPadding / 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                child: restaurantDetailAsync.when(
                  loading: () => RestaurantInfo(
                    name: restaurantName,
                    foodType: restaurantCategories,
                    rating: restaurantRating,
                    numOfRating: restaurant?.ratingCount ?? 200,
                    deliveryFee: restaurant?.deliveryFee ?? 'Free',
                    deliveryTime: restaurant?.deliveryTime ?? 25,
                  ),
                  error: (_, __) => RestaurantInfo(
                    name: restaurantName,
                    foodType: restaurantCategories,
                    rating: restaurantRating,
                    numOfRating: restaurant?.ratingCount ?? 200,
                    deliveryFee: restaurant?.deliveryFee ?? 'Free',
                    deliveryTime: restaurant?.deliveryTime ?? 25,
                  ),
                  data: (detail) => RestaurantInfo(
                    name: restaurantName,
                    foodType: detail?.foodTypes.isNotEmpty == true
                        ? detail!.foodTypes
                        : restaurantCategories,
                    rating: restaurantRating,
                    numOfRating:
                        detail?.ratingCount ?? restaurant?.ratingCount ?? 200,
                    deliveryFee: detail?.deliveryFee ??
                        restaurant?.deliveryFee ??
                        'Free',
                    deliveryTime:
                        detail?.deliveryTime ?? restaurant?.deliveryTime ?? 25,
                    takeAwayLabel: detail?.takeAwayLabel ?? 'Take away',
                  ),
                ),
              ),
              if (restaurantId != null)
                restaurantDetailAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: defaultPadding,
                      vertical: defaultPadding / 2,
                    ),
                    child: _MissingDataNotice(
                      message:
                          'Restaurant details are unavailable right now for this partner.',
                    ),
                  ),
                  data: (detail) => detail == null
                      ? const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: defaultPadding,
                            vertical: defaultPadding / 2,
                          ),
                          child: _MissingDataNotice(
                            message:
                                'This partner is missing restaurant detail data.',
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              const SizedBox(height: defaultPadding),
              featuredItemsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(defaultPadding),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: defaultPadding),
                  child: _MissingDataNotice(
                    message:
                        'Featured items are unavailable right now for this partner.',
                  ),
                ),
                data: (items) => FeaturedItems(items: items),
              ),
              menuTabsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(defaultPadding),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => menuItemsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(defaultPadding),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: defaultPadding),
                    child: _MissingDataNotice(
                      message: 'Menu items are unavailable right now.',
                    ),
                  ),
                  data: (items) => items.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: defaultPadding,
                          ),
                          child: _MissingDataNotice(
                            message:
                                'This partner does not have any menu items yet.',
                          ),
                        )
                      : Items(
                          tabs: const [],
                          items: items,
                          restaurantPriceTier: restaurant?.priceTier ?? 2,
                        ),
                ),
                data: (tabs) => menuItemsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(defaultPadding),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: defaultPadding),
                    child: _MissingDataNotice(
                      message: 'Menu items are unavailable right now.',
                    ),
                  ),
                  data: (items) => Items(
                    tabs: tabs,
                    items: items,
                    restaurantPriceTier: restaurant?.priceTier ?? 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissingDataNotice extends StatelessWidget {
  const _MissingDataNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
