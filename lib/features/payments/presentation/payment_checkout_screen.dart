import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants.dart';
import '../../../data/providers/auth_provider.dart';
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

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final user = authState.valueOrNull;

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
              onPressed: paymentState.isSubmitting || user == null
                  ? null
                  : () {
                      if (!_formKey.currentState!.validate()) {
                        return;
                      }

                      ref
                          .read(paymentControllerProvider.notifier)
                          .startMpesaCheckout(
                            orderId: widget.orderId,
                            userId: user.id,
                            phoneNumber: _phoneController.text.trim(),
                            amount: widget.amount,
                          );
                    },
              child: const Text('Pay with M-Pesa'),
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
                'Payment confirmed. Your order will continue to processing.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
