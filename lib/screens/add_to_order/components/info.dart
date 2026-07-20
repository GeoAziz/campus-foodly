import 'package:flutter/material.dart';

import '../../../components/app_image.dart';
import '../../../components/price_range_and_food_type.dart';
import '../../../constants.dart';
import '../../../data/models/menu_item.dart';

class Info extends StatelessWidget {
  const Info({super.key, this.menuItem});

  final MenuItem? menuItem;

  @override
  Widget build(BuildContext context) {
    final name = menuItem?.name ?? 'Cookie Sandwich';
    final description = menuItem?.description.isNotEmpty == true
        ? menuItem!.description
        : 'Shortbread, chocolate turtle cookies, and red velvet. 8 ounces cream cheese, softened.';
    final category = menuItem?.category.isNotEmpty == true
        ? menuItem!.category
        : 'Dessert';
    final image = menuItem?.image;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1.33,
          child: image != null && image.isNotEmpty
              ? AppImage(
                  source: image,
                  fit: BoxFit.cover,
                )
              : Image.asset(
                  'assets/images/Header-image.png',
                  fit: BoxFit.cover,
                ),
        ),
        const SizedBox(height: defaultPadding),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              PriceRangeAndFoodtype(
                foodType: [category],
              ),
              if (menuItem != null) _DishFacts(menuItem: menuItem!),
            ],
          ),
        ),
      ],
    );
  }
}

/// Compact display of the deeper menu-item metadata (portion, prep time,
/// calories, spice, dietary tags, allergens, ingredients). Each row is only
/// rendered when the underlying data is present, so items without the extra
/// fields simply show nothing.
class _DishFacts extends StatelessWidget {
  const _DishFacts({required this.menuItem});

  final MenuItem menuItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final facts = <String>[
      if (menuItem.portion.isNotEmpty) menuItem.portion,
      if (menuItem.prepTimeMins > 0) '${menuItem.prepTimeMins} min',
      if (menuItem.calories > 0) '${menuItem.calories} kcal',
      if (menuItem.spiceLevel > 0)
        'Spice ${'🌶️' * menuItem.spiceLevel}',
    ];

    final chips = <Widget>[
      for (final tag in menuItem.dietary)
        _Tag(label: tag, color: Colors.green),
      if (menuItem.isPopular) const _Tag(label: 'Popular', color: Colors.orange),
    ];

    final hasAllergens = menuItem.allergens
        .where((a) => a.toLowerCase() != 'none')
        .isNotEmpty;

    if (facts.isEmpty && chips.isEmpty && menuItem.ingredients.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (facts.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            facts.join('   •   '),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
        if (menuItem.ingredients.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Ingredients', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            menuItem.ingredients.join(', '),
            style: theme.textTheme.bodyMedium,
          ),
        ],
        if (hasAllergens) ...[
          const SizedBox(height: 12),
          Text(
            'Allergens: ${menuItem.allergens.where((a) => a.toLowerCase() != 'none').join(', ')}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.error),
          ),
        ],
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
