/// Extracted from: lib/screens/details/components/iteams.dart
/// Featured menu items with dynamic image generation
/// Used in: Items component on details page

import 'package:flutter/material.dart';

final List<Tab> demoTabs = <Tab>[
  const Tab(child: Text('Most Populars')),
  const Tab(child: Text('Beef & Lamb')),
  const Tab(child: Text('Seafood')),
  const Tab(child: Text('Appetizers')),
  const Tab(child: Text('Dim Sum')),
];

final List<Map<String, dynamic>> demoMenuItems = List.generate(
  3,
  (index) => {
    "image": "assets/images/featured _items_${index + 1}.png",
    "title": "Cookie Sandwich",
    "description": "Shortbread, chocolate turtle cookies, and red velvet.",
    "price": 7.4,
    "foodType": "Chinese",
    "priceRange": "\$" * 2,
  },
);
