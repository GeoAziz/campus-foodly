import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/section_title.dart';
import '../../../constants.dart';
import '../../../data/providers/filter_provider.dart';

class Dietaries extends ConsumerWidget {
  const Dietaries({super.key});

  static const List<Map<String, dynamic>> demoDietaries = [
    {"title": "Any", "isActive": false},
    {"title": "Vegetarian", "isActive": false},
    {"title": "Vegan", "isActive": false},
    {"title": "Gluten-Free", "isActive": false},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(restaurantFilterProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: "Dietary",
          // When press the clean all
          press: () =>
              ref.read(restaurantFilterProvider.notifier).setDietary('Any'),
          isMainSection: false,
        ),
        const SizedBox(height: defaultPadding),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 10,
            children: List.generate(
              demoDietaries.length,
              (index) => ElevatedButton(
                onPressed: () => ref
                    .read(restaurantFilterProvider.notifier)
                    .setDietary(demoDietaries[index]["title"] as String),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(56, 40),
                  backgroundColor:
                      filterState.dietary == demoDietaries[index]["title"]
                          ? primaryColor
                          : bodyTextColor,
                ),
                child: Text(demoDietaries[index]["title"]),
              ),
            ),
          ),
        )
      ],
    );
  }
}
