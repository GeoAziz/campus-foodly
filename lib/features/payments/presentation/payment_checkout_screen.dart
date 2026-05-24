import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants.dart';
import '../../../core/routes.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/cart_provider.dart';
import '../../../data/providers/order_provider.dart';
import '../../../features/profile/providers/profile_provider.dart';
import '../models/payment_status.dart';
import '../providers/payment_provider.dart';

class PaymentCheckoutScreen extends ConsumerStatefulWidget {
  const PaymentCheckoutScreen({
    super.key,
    required this.orderId,
    required this.amount,
  });

  final String orderId;
  final double amount;

  @override
  ConsumerState<PaymentCheckoutScreen> createState() =>
      _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends ConsumerState<PaymentCheckoutScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  ProviderSubscription<PaymentState>? _paymentStatusSub;

  @override
  void initState() {
    super.initState();
    _setupPaymentStatusListener();
  }

  void _setupPaymentStatusListener() {
    _paymentStatusSub = ref.listenManual<PaymentState>(
      paymentControllerProvider,
      (previous, current) async {
        if (previous?.status != PaymentStatus.succeeded &&
            current.status == PaymentStatus.succeeded &&
            mounted) {
          // Payment succeeded - create order from cart
          await _handlePaymentSuccess(current.paymentId);
        }

        if (current.status == PaymentStatus.failed && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                current.errorMessage ?? 'Payment failed. Please try again.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  Future<void> _handlePaymentSuccess(String? paymentId) async {
    if (paymentId == null) return;

    try {
      final authState = ref.read(authControllerProvider);
      final user = authState.valueOrNull;
      if (user == null) throw StateError('User not authenticated');

      final cartItems = ref.read(cartProvider);
      if (cartItems.isEmpty) {
        throw StateError('Cart is empty - cannot create order');
      }

      final addresses = await ref.read(userAddressesProvider.future);
      if (addresses.isEmpty) {
        throw StateError('Please add a delivery address before checkout');
      }
      final selectedAddress = addresses.firstWhere(
        (address) => address.isDefault,
        orElse: () => addresses.first,
      );

      // Create order from cart
      final order =
          await ref.read(orderControllerProvider.notifier).createOrderFromCart(
                userId: user.id,
                cartItems: cartItems,
                totalAmount: widget.amount,
                deliveryAddressId: selectedAddress.id,
                deliveryAddressLabel: selectedAddress.label,
                deliveryAddressLine: selectedAddress.formattedAddress,
              );

      // Link payment to order
      await ref
          .read(paymentRepositoryProvider)
          .linkOrderToPayment(paymentId, order.id);

      // Clear cart
      ref.read(cartProvider.notifier).clear();

      if (!mounted) return;

      // Navigate to order tracking with real order ID
      context.goNamed(
        AppRoutes.orderTracking,
        pathParameters: {'orderId': order.id},
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully! 🎉'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating order: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _paymentStatusSub?.close();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final user = authState.valueOrNull;
    final addressesAsync = ref.watch(userAddressesProvider);
    final addresses = addressesAsync.valueOrNull ?? const [];
    final hasAddress = addresses.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('M-Pesa Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order: ${widget.orderId}'),
            const SizedBox(height: 8),
            Text('Amount: KES ${widget.amount.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text(
              hasAddress
                  ? 'Delivery address: ${addresses.firstWhere((address) => address.isDefault, orElse: () => addresses.first).formattedAddress}'
                  : 'Delivery address: Missing',
              style: TextStyle(
                color: hasAddress ? titleColor : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!hasAddress)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  onPressed: () =>
                      context.pushNamed(AppRoutes.profileAddresses),
                  icon: const Icon(Icons.add_location_alt_rounded),
                  label: const Text('Add delivery address'),
                ),
              ),
            const SizedBox(height: defaultPadding),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'M-Pesa phone number',
                ),
                validator: (value) {
                  final normalized = value?.trim() ?? '';
                  if (normalized.length < 10) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: defaultPadding),
            ElevatedButton(
              onPressed: paymentState.isSubmitting ||
                      user == null ||
                      !hasAddress
                  ? null
                  : () {
                      if (!_formKey.currentState!.validate()) {
                        return;
                      }

                      // Show confirmation dialog before payment
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirm Payment'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Please review your payment details:'),
                              const SizedBox(height: 16),
                              Text(
                                'Amount: Ksh ${widget.amount.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Phone: ${_phoneController.text.trim()}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'You will receive an M-Pesa prompt on your phone. Enter your PIN to complete the payment.',
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                ref
                                    .read(paymentControllerProvider.notifier)
                                    .startMpesaCheckout(
                                      orderId: widget.orderId,
                                      userId: user.id,
                                      phoneNumber: _phoneController.text.trim(),
                                      amount: widget.amount,
                                    );
                              },
                              child: const Text('Proceed to Payment'),
                            ),
                          ],
                        ),
                      );
                    },
              child: paymentState.isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Pay with M-Pesa'),
            ),
            const SizedBox(height: defaultPadding),
            Text('Payment status: ${paymentState.status.name}'),
            if (paymentState.paymentId != null) ...[
              const SizedBox(height: 8),
              Text('Payment reference: ${paymentState.paymentId}'),
            ],
            if (paymentState.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                paymentState.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ensure MPESA_BACKEND_URL is set and your Cloud Function is deployed.',
              ),
            ],
            if (paymentState.status == PaymentStatus.succeeded) ...[
              const SizedBox(height: defaultPadding),
              const Text(
                'Payment confirmed. Creating your order...',
                style: TextStyle(color: Colors.green),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
