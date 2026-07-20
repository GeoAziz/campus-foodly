import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants.dart';
import '../../data/providers/auth_provider.dart';
import '../providers/admin_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessAsync = ref.watch(adminAccessProvider);
    final user = ref.watch(authControllerProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: accessAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Admin access failed: ${error.toString()}'),
          ),
          data: (hasAccess) {
            if (!hasAccess || user == null) {
              return const Center(
                child: Text('You do not have admin privileges.'),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () => ref
                      .read(adminOperationsProvider)
                      .createRestaurant('New Menu Item', 'Nairobi'),
                  child: const Text('Create Menu/Restaurant Entry'),
                ),
                const SizedBox(height: defaultPadding),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(adminOperationsProvider).seedDemoOrder(user.id),
                  child: const Text('Create Demo Order'),
                ),
                const SizedBox(height: defaultPadding),
                Expanded(
                  child: FutureBuilder(
                    future: ref
                        .read(adminOperationsProvider)
                        .fetchRecentOrders(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final orders = snapshot.data ?? const [];
                      if (orders.isEmpty) {
                        return const Center(
                            child: Text('No orders to manage.'));
                      }

                      return ListView.builder(
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return ListTile(
                            title: Text(order.id),
                            subtitle: Text(order.status),
                            trailing: TextButton(
                              onPressed: () => ref
                                  .read(adminOperationsProvider)
                                  .markOrderAsPreparing(order),
                              child: const Text('Mark Preparing'),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
