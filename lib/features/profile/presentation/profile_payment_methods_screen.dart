import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers/auth_provider.dart';
import '../providers/payment_methods_controller.dart';

class ProfilePaymentMethodsScreen extends ConsumerWidget {
  const ProfilePaymentMethodsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.valueOrNull;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment Methods')),
        body: const Center(child: Text('User not found')),
      );
    }

    final paymentState = ref.watch(paymentMethodsControllerProvider(user.id));
    final controller =
        ref.read(paymentMethodsControllerProvider(user.id).notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        elevation: 0,
      ),
      body: paymentState.isLoading && paymentState.methods.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : paymentState.methods.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.credit_card_off,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No payment methods',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add a credit or debit card',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: paymentState.methods.length,
                  itemBuilder: (context, index) {
                    final method = paymentState.methods[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Icon(
                            _getPaymentIcon(method.type),
                            size: 32,
                          ),
                          title: Text(
                            method.displayName,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              if (method.expiryMonth != null &&
                                  method.expiryYear != null)
                                Text(
                                  'Expires: ${method.expiryMonth}/${method.expiryYear}',
                                ),
                              if (method.isDefault)
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
                                          .withValues(alpha: 0.15),
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(4),
                                      ),
                                    ),
                                    child: Text(
                                      'Default',
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
                              if (!method.isDefault)
                                PopupMenuItem(
                                  child: const Text('Set as Default'),
                                  onTap: () {
                                    controller
                                        .setDefaultPaymentMethod(method.id);
                                  },
                                ),
                              PopupMenuItem(
                                child: const Text('Delete'),
                                onTap: () {
                                  _showDeleteDialog(
                                      context, method, controller);
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment method integration coming soon'),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    dynamic method,
    dynamic controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Method?'),
        content: Text(
          'Are you sure you want to delete ${method.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.deletePaymentMethod(method.id);
              Navigator.pop(context);
            },
            child: Text('Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  IconData _getPaymentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'card':
        return Icons.credit_card;
      case 'paypal':
        return Icons.account_balance_wallet;
      case 'apple_pay':
        return Icons.apple;
      case 'google_pay':
        return Icons.payment;
      default:
        return Icons.payment;
    }
  }
}
