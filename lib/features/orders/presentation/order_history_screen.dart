import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../constants.dart';
import '../../../core/routes.dart';
import '../providers/order_history_provider.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(userOrderHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: defaultPadding),
                  Text(
                    'No Orders Yet',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start ordering delicious food!',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: defaultPadding * 2),
                  ElevatedButton(
                    onPressed: () => context.goNamed(AppRoutes.app),
                    child: const Text('Start Shopping'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(defaultPadding),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return OrderHistoryCard(order: order);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: defaultPadding),
              Text('Error: $error'),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderHistoryCard extends StatelessWidget {
  const OrderHistoryCard({super.key, required this.order});

  final dynamic order;

  @override
  Widget build(BuildContext context) {
    final createdAt = order['created_at'] as DateTime?;
    final formattedDate =
        createdAt != null ? DateFormat('MMM d, yyyy').format(createdAt) : 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: defaultPadding),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          final orderId = order['id'] as String?;
          if (orderId != null) {
            context.pushNamed(
              AppRoutes.orderTracking,
              pathParameters: {'orderId': orderId},
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Order ID and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order['order_number'] ?? order['id']?.toString().substring(0, 8).toUpperCase() ?? 'N/A'}',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  _buildStatusBadge(context, order['status'] as String?),
                ],
              ),
              const SizedBox(height: defaultPadding),
              // Vendor and Items
              Text(
                order['vendor_name'] as String? ?? 'Restaurant',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                '${order['item_count'] ?? 1} items • KES ${order['total'] ?? 0}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: defaultPadding),
              // Quick Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final orderId = order['id'] as String?;
                        if (orderId != null) {
                          context.pushNamed(
                            AppRoutes.orderTracking,
                            pathParameters: {'orderId': orderId},
                          );
                        }
                      },
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('Details'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Reorder functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reorder feature coming soon')),
                        );
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Reorder'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String? status) {
    final (backgroundColor, textColor, icon, label) =
        _getStatusStyle(status ?? 'pending');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: textColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  (Color, Color, IconData, String) _getStatusStyle(String status) {
    return switch (status.toLowerCase()) {
      'delivered' => (
        Colors.green,
        Colors.green,
        Icons.check_circle,
        'Delivered'
      ),
      'preparing' => (Colors.blue, Colors.blue, Icons.schedule, 'Preparing'),
      'ready' => (Colors.orange, Colors.orange, Icons.done_all, 'Ready'),
      'picked_up' || 'on_the_way' => (
        Colors.purple,
        Colors.purple,
        Icons.local_shipping,
        'On Way'
      ),
      'cancelled' => (Colors.red, Colors.red, Icons.cancel, 'Cancelled'),
      _ => (Colors.grey, Colors.grey, Icons.pending_actions, 'Pending'),
    };
  }
}
