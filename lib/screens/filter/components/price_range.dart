import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/section_title.dart';
import '../../../constants.dart';
import '../../../data/providers/filter_provider.dart';

class PriceRange extends ConsumerWidget {
  const PriceRange({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(restaurantFilterProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: "Price Range",
          press: () =>
              ref.read(restaurantFilterProvider.notifier).setPriceTier(5),
          isMainSection: false,
        ),
        const SizedBox(height: defaultPadding),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const SizedBox(width: defaultPadding),
              ...List.generate(
                // For demo i'm using length 5
                5, // Price limit
                (index) => Padding(
                  padding: const EdgeInsets.only(right: defaultPadding),
                  child: RoundedButton(
                    index: index,
                    isActive: (index + 1) == filterState.maxPriceTier,
                    press: () => ref
                        .read(restaurantFilterProvider.notifier)
                        .setPriceTier(index + 1),
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}

class RoundedButton extends StatelessWidget {
  const RoundedButton({
    super.key,
    this.isActive = false,
    required this.index,
    required this.press,
  });

  final bool isActive;
  final int index;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: isActive ? primaryColor : inputColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
            side: BorderSide(
                color: isActive
                    ? primaryColor
                    : bodyTextColor.withValues(alpha: 0.1)),
          ),
        ),
        onPressed: press,
        child: Text(
          "\$" * (index + 1),
          style: TextStyle(
            fontWeight: FontWeight.normal,
            color: isActive ? Colors.white : titleColor,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
