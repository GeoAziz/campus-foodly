import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/section_title.dart';
import '../../../constants.dart';
import '../../../data/providers/filter_provider.dart';

class Categories extends ConsumerWidget {
  const Categories({super.key});

  static const List<Map<String, dynamic>> demoCategories = [
    {"title": "All", "isActive": false},
    {"title": "Brunch", "isActive": false},
    {"title": "Dinner", "isActive": false},
    {"title": "Burgers", "isActive": true},
    {"title": "Chinese", "isActive": false},
    {"title": "Pizza", "isActive": false},
    {"title": "Salads", "isActive": false},
    {"title": "Soups", "isActive": false},
    {"title": "Breakfast", "isActive": false},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(restaurantFilterProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: "Categories",
          press: () =>
              ref.read(restaurantFilterProvider.notifier).setCategory('All'),
          isMainSection: false,
        ),
        const SizedBox(height: defaultPadding),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Wrap(
            spacing: defaultPadding / 2,
            children: List.generate(
              demoCategories.length,
              (index) => ElevatedButton(
                onPressed: () => ref
                    .read(restaurantFilterProvider.notifier)
                    .setCategory(demoCategories[index]["title"] as String),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(56, 40),
                  backgroundColor:
                      filterState.category == demoCategories[index]["title"]
                          ? primaryColor
                          : bodyTextColor,
                ),
                child: Text(demoCategories[index]["title"]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
