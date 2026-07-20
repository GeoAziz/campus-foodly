import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants.dart';
import '../../../data/models/order.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/order_provider.dart';

final _ownerRestaurantIdProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) return null;

  final snapshot = await FirebaseFirestore.instance
      .collection('restaurants')
      .where('ownerId', isEqualTo: user.id)
      .limit(1)
      .get();

  if (snapshot.docs.isEmpty) return null;
  return snapshot.docs.first.id;
});

final _restaurantOrdersProvider =
    StreamProvider.family<List<Order>, String>((ref, restaurantId) {
  return ref.watch(orderRepositoryProvider).watchOrdersForRestaurant(restaurantId);
});

class RestaurantOwnerDashboardScreen extends ConsumerWidget {
  const RestaurantOwnerDashboardScreen({super.key});

  static const _transitions = {
    'pending': ['accepted', 'cancelled'],
    'accepted': ['preparing', 'cancelled'],
    'preparing': ['ready'],
    'ready': [],
    'cancelled': [],
    'picked_up': [],
    'delivered': [],
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantIdAsync = ref.watch(_ownerRestaurantIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Restaurant Dashboard')),
      body: restaurantIdAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (restaurantId) {
          if (restaurantId == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(defaultPadding),
                child: Text(
                  'No restaurant found for your account. Contact admin to set up your restaurant.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ref.watch(_restaurantOrdersProvider(restaurantId)).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading orders: $e')),
                data: (orders) {
                  if (orders.isEmpty) {
                    return const Center(child: Text('No incoming orders.'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(defaultPadding),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final nextStatuses = _transitions[order.status] ?? [];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Order #${order.id.substring(0, 8)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  _StatusChip(status: order.status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...order.items.map((item) => Text(
                                    '${item.quantity}× ${item.name}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  )),
                              const SizedBox(height: 8),
                              Text(
                                'Total: KES ${order.totalAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              if (nextStatuses.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  children: nextStatuses.map((nextStatus) {
                                    return FilledButton.tonal(
                                      onPressed: () async {
                                        await ref
                                            .read(orderRepositoryProvider)
                                            .updateOrderStatus(
                                                order.id, nextStatus);
                                      },
                                      child: Text(_statusLabel(nextStatus)),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
        },
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'Accept';
      case 'preparing':
        return 'Start Preparing';
      case 'ready':
        return 'Mark Ready';
      case 'cancelled':
        return 'Cancel';
      default:
        return status;
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'pending' => Colors.orange,
      'accepted' => Colors.blue,
      'preparing' => Colors.purple,
      'ready' => Colors.green,
      'picked_up' => Colors.teal,
      'delivered' => Colors.green.shade800,
      'cancelled' => Colors.red,
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
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
