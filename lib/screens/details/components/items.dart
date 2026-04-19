import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../components/cards/item_card.dart';
import '../../../core/constants.dart';
import '../../../core/routes.dart';
import '../../../data/models/menu_item.dart';
import '../../../data/models/menu_tab.dart';

class Items extends StatefulWidget {
  const Items({
    super.key,
    required this.tabs,
    required this.items,
    required this.restaurantPriceTier,
  });

  final List<MenuTabItem> tabs;
  final List<MenuItem> items;
  final int restaurantPriceTier;

  @override
  State<Items> createState() => _ItemsState();
}

class _ItemsState extends State<Items> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.tabs.isNotEmpty)
              DefaultTabController(
                length: widget.tabs.length,
                child: TabBar(
                  isScrollable: true,
                  unselectedLabelColor: titleColor,
                  labelStyle: Theme.of(context).textTheme.titleLarge,
                  tabs: widget.tabs
                      .map((tab) => Tab(child: Text(tab.title)))
                      .toList(growable: false),
                ),
              ),
            const SizedBox(height: defaultPadding),
            Text(
              'Menu items are not available for this partner yet.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    final sortedTabs = [...widget.tabs]..sort(
        (left, right) => left.position.compareTo(right.position),
      );

    final selectedTabTitle =
        sortedTabs.isNotEmpty && selectedTab < sortedTabs.length
            ? sortedTabs[selectedTab].title
            : null;

    final filteredItems = selectedTabTitle == null
        ? widget.items
        : widget.items.where((item) {
            final category = item.category.trim().toLowerCase();
            final tabLabel = selectedTabTitle.trim().toLowerCase();
            if (category.isEmpty) {
              return selectedTab == 0;
            }
            if (selectedTab == 0) {
              return true;
            }
            return category == tabLabel;
          }).toList(growable: false);

    final visibleItems = filteredItems.isEmpty ? widget.items : filteredItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sortedTabs.isNotEmpty)
          DefaultTabController(
            length: sortedTabs.length,
            child: TabBar(
              isScrollable: true,
              unselectedLabelColor: titleColor,
              labelStyle: Theme.of(context).textTheme.titleLarge,
              onTap: (value) {
                setState(() {
                  selectedTab = value;
                });
              },
              tabs: sortedTabs
                  .map((tab) => Tab(child: Text(tab.title)))
                  .toList(growable: false),
            ),
          ),
        ...List.generate(
          visibleItems.length,
          (index) {
            final item = visibleItems[index];
            final safePriceTier =
                widget.restaurantPriceTier < 1 ? 2 : widget.restaurantPriceTier;
            final resolvedPriceRange = item.priceRange.trim().isNotEmpty
                ? item.priceRange
                : List.filled(safePriceTier, '\$').join();
            final resolvedFoodType = item.foodType.trim().isNotEmpty
                ? item.foodType
                : (item.category.trim().isNotEmpty ? item.category : 'Chinese');

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: defaultPadding,
                vertical: defaultPadding / 2,
              ),
              child: ItemCard(
                title: item.name,
                description: item.description,
                image: item.image,
                foodType: resolvedFoodType,
                price: item.price,
                priceRange: resolvedPriceRange,
                press: () => context.pushNamed(AppRoutes.addToOrder),
              ),
            );
          },
        ),
      ],
    );
  }
}
