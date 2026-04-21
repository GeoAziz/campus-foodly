import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/buttons/primary_button.dart';
import '../../../constants.dart';
import '../../../core/routes.dart';
import '../providers/order_tracking_provider.dart';

class OrderDeliveredScreen extends ConsumerWidget {
  const OrderDeliveredScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderByIdProvider(orderId));
    final paymentAsync = ref.watch(paymentByOrderIdProvider(orderId));

    final order = orderAsync.valueOrNull;
    final payment = paymentAsync.valueOrNull;
    final deliveredAt = payment?.updatedAt ?? order?.createdAt ?? DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Order Delivered')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(defaultPadding),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E8E3E), Color(0xFF14532D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 88,
                      width: 88,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: defaultPadding),
                    Text(
                      'Your order has arrived',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Thanks for ordering with us. Here is your delivery summary.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: defaultPadding),
              _SummaryCard(
                orderId: orderId,
                deliveredAt: deliveredAt,
                totalPaid: payment?.amount ?? order?.totalAmount,
                itemCount: order?.items.length,
                deliveryAddress: _deliveryAddressLabel(order?.deliveryAddressLabel, order?.deliveryAddressLine),
                paymentMethod: _paymentMethodLabel(payment?.provider),
                paymentStatus: _paymentStatusLabel(payment?.status),
                phoneNumber: payment?.phoneNumber,
                isLoading: orderAsync.isLoading || paymentAsync.isLoading,
              ),
              const SizedBox(height: defaultPadding),
              _ActionCard(orderId: orderId),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.orderId,
    required this.deliveredAt,
    required this.totalPaid,
    required this.itemCount,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.phoneNumber,
    required this.isLoading,
  });

  final String orderId;
  final DateTime deliveredAt;
  final double? totalPaid;
  final int? itemCount;
  final String deliveryAddress;
  final String paymentMethod;
  final String paymentStatus;
  final String? phoneNumber;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final summaryRows = [
      ('Order ID', orderId),
      ('Delivered at', _formatDateTime(deliveredAt)),
      (
        'Total paid',
        totalPaid == null ? 'Loading...' : '\$${totalPaid!.toStringAsFixed(2)}',
      ),
      (
        'Items',
        itemCount == null ? 'Loading...' : '$itemCount item${itemCount == 1 ? '' : 's'}',
      ),
      ('Delivery address', deliveryAddress),
      ('Payment method', paymentMethod),
      ('Payment status', paymentStatus),
      if (phoneNumber != null && phoneNumber!.isNotEmpty)
        ('Paid with', phoneNumber!),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF2F2F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery summary',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            isLoading
                ? 'Loading your final order details...'
                : 'This gives the user a clear endpoint after tracking.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: bodyTextColor,
                ),
          ),
          const SizedBox(height: defaultPadding),
          for (var index = 0; index < summaryRows.length; index++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    summaryRows[index].$1,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: bodyTextColor,
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    summaryRows[index].$2,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            if (index != summaryRows.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF2F2F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What next?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: defaultPadding),
          PrimaryButton(
            text: 'Back to home',
            press: () => context.goNamed(AppRoutes.app),
          ),
          const SizedBox(height: defaultPadding / 2),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Rating flow is coming in the next update.'),
                ),
              );
            },
            icon: const Icon(Icons.star_rate_rounded),
            label: const Text('Rate this order'),
          ),
          const SizedBox(height: defaultPadding / 2),
          TextButton.icon(
            onPressed: () => context.goNamed(AppRoutes.orderDetails),
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Reorder from cart'),
          ),
          const SizedBox(height: defaultPadding / 2),
          TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Receipt for order $orderId will be available soon.'),
                ),
              );
            },
            icon: const Icon(Icons.receipt_long_rounded),
            label: const Text('View receipt'),
          ),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  final month = _monthName(local.month);
  return '$month ${local.day}, $hour:$minute $period';
}

String _monthName(int month) {
  const months = [
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

  return months[(month - 1).clamp(0, months.length - 1)];
}

String _paymentMethodLabel(String? provider) {
  switch ((provider ?? '').toLowerCase()) {
    case 'mpesa':
      return 'M-Pesa';
    case 'mpesa_mock':
      return 'M-Pesa (Sandbox)';
    default:
      return 'Payment method unavailable';
  }
}

String _paymentStatusLabel(String? status) {
  switch ((status ?? '').toLowerCase()) {
    case 'succeeded':
      return 'Paid';
    case 'processing':
      return 'Processing';
    case 'pending':
      return 'Pending confirmation';
    case 'failed':
      return 'Failed';
    default:
      return 'Unknown';
  }
}

String _deliveryAddressLabel(String? label, String? line) {
  if (line != null && line.isNotEmpty) {
    if (label != null && label.isNotEmpty) {
      return '$label - $line';
    }
    return line;
  }
  return 'Address unavailable';
}
