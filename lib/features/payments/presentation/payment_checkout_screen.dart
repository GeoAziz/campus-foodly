import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants.dart';
import '../../../core/routes.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/cart_provider.dart';
import '../../../data/providers/order_provider.dart';
import '../../../data/services/price_formatter.dart';
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
  final _couponController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  ProviderSubscription<PaymentState>? _paymentStatusSub;
  double _discount = 0;
  bool _applyingCoupon = false;
  String? _couponError;
  String? _appliedCouponCode;

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

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _applyingCoupon = true;
      _couponError = null;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('coupons')
          .where('code', isEqualTo: code)
          .where('active', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() => _couponError = 'Invalid or expired coupon code.');
        return;
      }

      final coupon = snapshot.docs.first.data();
      final expiry = coupon['expiresAt'];
      if (expiry is Timestamp && expiry.toDate().isBefore(DateTime.now())) {
        setState(() => _couponError = 'This coupon has expired.');
        return;
      }

      final discountType = coupon['discountType'] as String? ?? 'fixed';
      final discountValue = (coupon['discountValue'] as num?)?.toDouble() ?? 0;

      double discount;
      if (discountType == 'percentage') {
        discount = widget.amount * (discountValue / 100);
      } else {
        discount = discountValue;
      }

      // Cap discount at full amount
      discount = discount.clamp(0.0, widget.amount);

      setState(() {
        _discount = discount;
        _appliedCouponCode = code;
      });
    } catch (e) {
      setState(() => _couponError = 'Could not apply coupon. Try again.');
    } finally {
      if (mounted) {
        setState(() => _applyingCoupon = false);
      }
    }
  }

  @override
  void dispose() {
    _paymentStatusSub?.close();
    _phoneController.dispose();
    _couponController.dispose();
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
    final double finalAmount = (widget.amount - _discount).clamp(0.0, double.infinity).toDouble();

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Payment')),
      body: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Address',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              hasAddress
                  ? addresses
                      .firstWhere((address) => address.isDefault,
                          orElse: () => addresses.first)
                      .formattedAddress
                  : 'No address selected',
              style: TextStyle(
                color: hasAddress
                    ? titleColor
                    : Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Payment Amount',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_discount > 0) ...[
              Text(
                formatPrice(widget.amount),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    formatPrice(finalAmount),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.green,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '-${formatPrice(_discount)} (${ _appliedCouponCode})',
                      style: const TextStyle(
                          color: Colors.green, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ] else
              Text(
                formatPrice(widget.amount),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            const SizedBox(height: 16),
            // Coupon code field
            if (_appliedCouponCode == null) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _couponController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Coupon code',
                        errorText: _couponError,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _applyingCoupon ? null : _applyCoupon,
                    child: _applyingCoupon
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Apply'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
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
                                'Amount: ${formatPrice(finalAmount)}',
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
                                      amount: finalAmount,
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
            if (paymentState.errorMessage != null) ...[
              const SizedBox(height: defaultPadding),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                child: Text(
                  paymentState.errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
            if (paymentState.status == PaymentStatus.succeeded) ...[
              const SizedBox(height: defaultPadding),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                child: Text(
                  'Payment confirmed. Creating your order...',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
