import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/skeleton/skeleton_line.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../core/routes.dart';
import '../providers/addresses_controller.dart';

class ProfileAddressesScreen extends ConsumerWidget {
  const ProfileAddressesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.valueOrNull;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Saved Addresses')),
        body: const Center(child: Text('User not found')),
      );
    }

    final addressesState = ref.watch(addressesControllerProvider(user.id));
    final controller = ref.read(addressesControllerProvider(user.id).notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Addresses'),
        elevation: 0,
      ),
      body: addressesState.isLoading && addressesState.addresses.isEmpty
          ? SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: List.generate(
                    2,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonLine(
                                height: 16,
                                width: 120,
                              ),
                              const SizedBox(height: 12),
                              SkeletonLine(
                                height: 14,
                                width: double.infinity,
                              ),
                              const SizedBox(height: 8),
                              SkeletonLine(
                                height: 12,
                                width: 200,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : addressesState.addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No addresses yet',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first delivery address',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: addressesState.addresses.length,
                  itemBuilder: (context, index) {
                    final address = addressesState.addresses[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Icon(
                            _getLabelIcon(address.label),
                            size: 32,
                          ),
                          title: Text(
                            address.label,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(address.formattedAddress),
                              if (address.isDefault)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.15),
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(4),
                                      ),
                                    ),
                                    child: Text(
                                      'Default Address',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              if (!address.isDefault)
                                PopupMenuItem(
                                  child: const Text('Set as Default'),
                                  onTap: () {
                                    controller.setDefaultAddress(address.id);
                                  },
                                ),
                              PopupMenuItem(
                                child: const Text('Edit'),
                                onTap: () {
                                  context.pushNamed(
                                    AppRoutes.profileAddressAdd,
                                    queryParameters: {'addressId': address.id},
                                  );
                                },
                              ),
                              PopupMenuItem(
                                child: const Text('Delete'),
                                onTap: () {
                                  _showDeleteDialog(
                                      context, address, controller);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.pushNamed(AppRoutes.profileAddressAdd);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    dynamic address,
    dynamic controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address?'),
        content: Text('Are you sure you want to delete ${address.label}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.deleteAddress(address.id);
              Navigator.pop(context);
            },
            child: Text('Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  IconData _getLabelIcon(String label) {
    switch (label.toLowerCase()) {
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.business;
      default:
        return Icons.location_on;
    }
  }
}
