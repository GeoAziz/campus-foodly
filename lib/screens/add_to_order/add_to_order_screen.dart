import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants.dart';
import '../../core/routes.dart';
import '../../data/models/menu_item.dart';
import '../../data/providers/cart_provider.dart';
import '../../data/providers/ui_state_provider.dart';
import '../../data/services/logger_service.dart';
import 'components/info.dart';
import 'components/required_section_title.dart';
import 'components/rounded_checkbox_list_tile.dart';

class AddToOrderScreen extends ConsumerWidget {
  const AddToOrderScreen({super.key});

  static const List<String> choiceOfTopCookies = [
    'Choice of top Cookie',
    'Cookies and Cream',
    'Funfetti',
    'M and M',
    'Red Velvet',
    'Peanut Butter',
    'Snickerdoodle',
    'White Chocolate Macadamia',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addToOrderControllerProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(100))),
              backgroundColor: Colors.black.withOpacity(0.5),
              padding: EdgeInsets.zero,
            ),
            child: const Icon(Icons.close, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Info(),
              const SizedBox(height: defaultPadding),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const RequiredSectionTitle(title: "Choice of top Cookie"),
                    const SizedBox(height: defaultPadding),
                    ...List.generate(
                      choiceOfTopCookies.length,
                      (index) => RoundedCheckboxListTile(
                        isActive: index == state.choiceOfTopCookie,
                        text: choiceOfTopCookies[index],
                        press: () => ref
                            .read(addToOrderControllerProvider.notifier)
                            .selectTopCookie(index),
                      ),
                    ),
                    const SizedBox(height: defaultPadding),
                    const RequiredSectionTitle(
                        title: "Choice of Bottom Cookie"),
                    const SizedBox(height: defaultPadding),
                    ...List.generate(
                      choiceOfTopCookies.length,
                      (index) => RoundedCheckboxListTile(
                        isActive: index == state.choiceOfBottomCookie,
                        text: choiceOfTopCookies[index],
                        press: () => ref
                            .read(addToOrderControllerProvider.notifier)
                            .selectBottomCookie(index),
                      ),
                    ),
                    const SizedBox(height: defaultPadding),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 40,
                          width: 40,
                          child: ElevatedButton(
                            onPressed: () => ref
                                .read(addToOrderControllerProvider.notifier)
                                .decrementItems(),
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Icon(Icons.remove),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: defaultPadding),
                          child: Text(
                              state.numOfItems.toString().padLeft(2, '0'),
                              style: Theme.of(context).textTheme.titleLarge),
                        ),
                        SizedBox(
                          height: 40,
                          width: 40,
                          child: ElevatedButton(
                            onPressed: () => ref
                                .read(addToOrderControllerProvider.notifier)
                                .incrementItems(),
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Icon(Icons.add),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: defaultPadding),
                    ElevatedButton(
                      onPressed: () {
                        try {
                          ref.read(cartProvider.notifier).addItem(
                                MenuItem(
                                  id: 'cookie-${state.choiceOfTopCookie}-${state.choiceOfBottomCookie}',
                                  restaurantId: 'demo-desserts',
                                  name:
                                      '${choiceOfTopCookies[state.choiceOfTopCookie]} x ${choiceOfTopCookies[state.choiceOfBottomCookie]}',
                                  price: 11.98,
                                  image: 'assets/images/big_1.png',
                                  description:
                                      'Top: ${choiceOfTopCookies[state.choiceOfTopCookie]}, Bottom: ${choiceOfTopCookies[state.choiceOfBottomCookie]}',
                                  category: 'Dessert',
                                ),
                                quantity: state.numOfItems,
                              );
                          context.pushNamed(AppRoutes.orderDetails);
                        } on StateError catch (e) {
                          // Handle cross-restaurant validation error
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    e.message ?? 'Cannot add item to cart'),
                                backgroundColor:
                                    Theme.of(context).colorScheme.error,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                          LoggerService().w(
                              '[AddToOrder] Cross-restaurant error: ${e.message}');
                        } catch (e) {
                          // Handle unexpected errors
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                    'Failed to add item to cart. Please try again.'),
                                backgroundColor:
                                    Theme.of(context).colorScheme.error,
                              ),
                            );
                          }
                          LoggerService()
                              .e('[AddToOrder] Error adding item: $e');
                        }
                      },
                      child: const Text("Add to Order (\$11.98)"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: defaultPadding)
            ],
          ),
        ),
      ),
    );
  }
}
