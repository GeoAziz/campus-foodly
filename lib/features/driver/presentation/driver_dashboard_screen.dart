import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants.dart';
import '../../../core/routes.dart';
import '../../../data/models/order.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/order_provider.dart';

final _driverOrdersProvider = StreamProvider<List<Order>>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('orders')
      .where('deliveryPersonId', isEqualTo: user.id)
      .where('status', whereIn: ['accepted', 'picked_up'])
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Order.fromMap(doc.id, doc.data()))
          .toList(growable: false));
});

class DriverDashboardScreen extends ConsumerWidget {
  const DriverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(_driverOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Driver Dashboard')),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(defaultPadding),
                child: Text(
                  'No active deliveries assigned to you.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(defaultPadding),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order #${order.id.substring(0, 8)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          _StatusChip(status: order.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (order.deliveryAddressLine.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 16, color: Colors.red),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                order.deliveryAddressLine,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'Total: KES ${order.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => context.pushNamed(
                                AppRoutes.orderTracking,
                                pathParameters: {'orderId': order.id},
                              ),
                              child: const Text('View Details'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (order.status == 'accepted')
                            Expanded(
                              child: FilledButton(
                                onPressed: () async {
                                  await ref
                                      .read(orderRepositoryProvider)
                                      .updateOrderStatus(order.id, 'picked_up');
                                },
                                child: const Text('Picked Up'),
                              ),
                            ),
                          if (order.status == 'picked_up')
                            Expanded(
                              child: FilledButton(
                                onPressed: () async {
                                  await ref
                                      .read(orderRepositoryProvider)
                                      .updateOrderStatus(order.id, 'delivered');
                                },
                                child: const Text('Delivered'),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'accepted' => Colors.blue,
      'picked_up' => Colors.teal,
      'delivered' => Colors.green,
      _ => Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
