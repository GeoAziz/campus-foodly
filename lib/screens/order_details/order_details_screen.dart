import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/buttons/primary_button.dart';
import '../../constants.dart';
import '../../data/models/order.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/cart_provider.dart';
import '../../data/providers/order_provider.dart';
import '../../core/routes.dart';
import 'components/order_item_card.dart';
import 'components/price_row.dart';
import 'components/total_price.dart';

class OrderDetailsScreen extends ConsumerStatefulWidget {
  const OrderDetailsScreen({super.key});

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  String? _loadedOrdersForUserId;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.valueOrNull;

    if (user != null && _loadedOrdersForUserId != user.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadedOrdersForUserId = user.id;
        ref.read(orderControllerProvider.notifier).loadForUser(user.id);
      });
    }

    if (user == null) {
      _loadedOrdersForUserId = null;
    }

    final ordersState = ref.watch(orderControllerProvider);
    final orders = [...(ordersState.valueOrNull ?? const <Order>[])];
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.read(cartProvider.notifier).subtotal;
    final hasItems = cartItems.isNotEmpty;
    const draftOrderId = 'cart-draft';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Orders'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: defaultPadding),
              Text(
                'Order History',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: defaultPadding / 2),
              _OrderHistorySection(
                ordersState: ordersState,
                orders: orders,
              ),
              const SizedBox(height: defaultPadding * 1.5),
              Text(
                'Current Cart',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: defaultPadding / 2),
              if (hasItems) ...[
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
                      onRemove: () =>
                          ref.read(cartProvider.notifier).removeItem(item.id),
                      title: item.menuItem.name,
                      description: item.specialInstructions?.isNotEmpty == true
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
                PriceRow(text: 'Subtotal', price: subtotal),
                const SizedBox(height: defaultPadding / 2),
                const PriceRow(text: 'Delivery', price: 0),
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
                const SizedBox(height: defaultPadding),
              ] else ...[
                const Padding(
                  padding: EdgeInsets.only(top: 8, bottom: defaultPadding),
                  child: Text('Your cart is empty. Add a dish to continue.'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderHistorySection extends StatelessWidget {
  const _OrderHistorySection({
    required this.ordersState,
    required this.orders,
  });

  final AsyncValue<List<Order>> ordersState;
  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    if (ordersState.isLoading && orders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (ordersState.hasError && orders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Could not load orders: ${ordersState.error}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
        ),
      );
    }

    if (orders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No previous orders yet.'),
      );
    }

    return Column(
      children: orders.map((order) => _OrderHistoryCard(order: order)).toList(),
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  const _OrderHistoryCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final itemCount =
        order.items.fold<int>(0, (sum, item) => sum + item.quantity);
    final itemSummary = order.items.take(2).map((item) => item.name).join(', ');
    final hasMore = order.items.length > 2;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: defaultPadding / 2),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order ${order.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                order.status.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _formatOrderDate(order.createdAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: bodyTextColor,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            hasMore
                ? '$itemSummary +${order.items.length - 2} more'
                : itemSummary,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          Text(
            '$itemCount item${itemCount == 1 ? '' : 's'} • \$${order.totalAmount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

String _formatOrderDate(DateTime date) {
  final local = date.toLocal();
  final month = _monthLabel(local.month);
  final day = local.day.toString().padLeft(2, '0');
  final hour = (local.hour % 12 == 0 ? 12 : local.hour % 12).toString();
  final minute = local.minute.toString().padLeft(2, '0');
  final meridiem = local.hour >= 12 ? 'PM' : 'AM';
  return '$month $day, ${local.year} • $hour:$minute $meridiem';
}

String _monthLabel(int month) {
  const labels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return labels[(month - 1).clamp(0, labels.length - 1)];
}
