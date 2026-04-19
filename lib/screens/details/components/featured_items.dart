import 'package:flutter/material.dart';

import '../../../data/models/featured_item.dart';
import '../../../constants.dart';
import 'featured_item_card.dart';

class FeaturedItems extends StatelessWidget {
  const FeaturedItems({
    super.key,
    required this.items,
  });

  final List<FeaturedItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Featured Items",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: defaultPadding),
            Text(
              'Featured items are not available for this partner yet.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Text("Featured Items",
              style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: defaultPadding / 2),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...List.generate(
                items.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(left: defaultPadding),
                  child: FeaturedItemCard(
                    title: items[index].title,
                    image: items[index].image,
                    foodType: items[index].foodType,
                    priceRange: items[index].priceRange.isEmpty
                        ? r'$$'
                        : items[index].priceRange,
                    press: () {},
                  ),
                ),
              ),
              const SizedBox(width: defaultPadding),
            ],
          ),
        ),
      ],
    );
  }
}
