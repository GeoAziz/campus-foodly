import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'constants.dart';
import 'data/providers/ui_state_provider.dart';
import 'data/providers/cart_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/order_details/order_details_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/search/search_screen.dart';

class EntryPoint extends ConsumerWidget {
  const EntryPoint({super.key});

  static final List<Map<String, dynamic>> _navitems = [
    {'icon': 'assets/icons/home.svg', 'title': 'Home'},
    {'icon': 'assets/icons/search.svg', 'title': 'Search'},
    {'icon': 'assets/icons/order.svg', 'title': 'Orders'},
    {'icon': 'assets/icons/profile.svg', 'title': 'Profile'},
  ];

  static final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const OrderDetailsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(entryTabIndexProvider);

    // Initialize cart on entry point - loads persisted cart data from device storage
    // This triggers CartController.initializeCart() on first access
    final cartState = ref.watch(cartProvider);
    
    // Log cart initialization for debugging
    debugPrint('[EntryPoint] Cart initialized with ${cartState.length} items');

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: CupertinoTabBar(
        onTap: (value) =>
            ref.read(entryTabIndexProvider.notifier).state = value,
        currentIndex: selectedIndex,
        activeColor: primaryColor,
        inactiveColor: bodyTextColor,
        items: List.generate(
          _navitems.length,
          (index) => BottomNavigationBarItem(
            icon: SvgPicture.asset(
              _navitems[index]["icon"],
              height: 30,
              width: 30,
              colorFilter: ColorFilter.mode(
                  index == selectedIndex ? primaryColor : bodyTextColor,
                  BlendMode.srcIn),
            ),
            label: _navitems[index]["title"],
          ),
        ),
      ),
    );
  }
}
