import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/buttons/primary_button.dart';
import '../../constants.dart';
import '../../data/providers/cart_provider.dart';
import '../../core/routes.dart';
import 'components/order_item_card.dart';
import 'components/price_row.dart';
import 'components/total_price.dart';

class OrderDetailsScreen extends ConsumerWidget {
  const OrderDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.read(cartProvider.notifier).subtotal;
    final hasItems = cartItems.isNotEmpty;
    const draftOrderId = 'cart-draft';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Orders"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: hasItems
              ? Column(
                  children: [
                    const SizedBox(height: defaultPadding),
                    ...cartItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: defaultPadding / 2,
                        ),
                        child: OrderedItemCard(
                          onIncrement: () => ref
                              .read(cartProvider.notifier)
                              .incrementQuantity(item.id),
                          onDecrement: () => ref
                              .read(cartProvider.notifier)
                              .decrementQuantity(item.id),
                          onRemove: () => ref
                              .read(cartProvider.notifier)
                              .removeItem(item.id),
                          title: item.menuItem.name,
                          description:
                              item.specialInstructions?.isNotEmpty == true
                                  ? item.specialInstructions
                                  : item.menuItem.description.isNotEmpty
                                      ? item.menuItem.description
                                      : item.menuItem.category.isNotEmpty
                                          ? item.menuItem.category
                                          : 'Added to cart',
                          numOfItem: item.quantity,
                          price: item.totalPrice,
                        ),
                      ),
                    ),
                    PriceRow(text: "Subtotal", price: subtotal),
                    const SizedBox(height: defaultPadding / 2),
                    const PriceRow(text: "Delivery", price: 0),
                    const SizedBox(height: defaultPadding / 2),
                    TotalPrice(price: subtotal),
                    const SizedBox(height: defaultPadding * 2),
                    PrimaryButton(
                      text: 'Checkout (\$${subtotal.toStringAsFixed(2)})',
                      press: () => context.pushNamed(
                        AppRoutes.paymentCheckout,
                        queryParameters: {
                          'orderId': draftOrderId,
                          'amount': subtotal.toStringAsFixed(2),
                        },
                      ),
                    ),
                    const SizedBox(height: defaultPadding / 2),
                    OutlinedButton(
                      onPressed: () => context.pushNamed(
                        AppRoutes.orderTracking,
                        pathParameters: {'orderId': draftOrderId},
                      ),
                      child: const Text('Track Order'),
                    ),
                  ],
                )
              : const Padding(
                  padding: EdgeInsets.only(top: 64),
                  child: Center(
                    child: Text('Your cart is empty. Add a dish to continue.'),
                  ),
                ),
        ),
      ),
    );
  }
}
