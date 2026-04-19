import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants.dart';
import '../../data/providers/filter_provider.dart';
import 'components/categories.dart';
import 'components/dietaries.dart';
import 'components/price_range.dart';

class FilterScreen extends ConsumerWidget {
  const FilterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(restaurantFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Filters"),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(restaurantFilterProvider.notifier).reset(),
            child: const Text('Reset'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: defaultPadding),
              const Categories(),
              const SizedBox(height: defaultPadding),
              const Dietaries(),
              const SizedBox(height: defaultPadding),
              const PriceRange(),
              const SizedBox(height: defaultPadding),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Minimum Rating: ${filterState.minRating.toStringAsFixed(1)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Slider(
                      min: 0,
                      max: 5,
                      divisions: 10,
                      value: filterState.minRating,
                      onChanged: (value) => ref
                          .read(restaurantFilterProvider.notifier)
                          .setMinRating(value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: defaultPadding),
            ],
          ),
        ),
      ),
    );
  }
}
