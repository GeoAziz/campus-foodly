import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Available payment methods
enum PaymentMethod {
  mpesa('M-Pesa', Icons.mobile_screen_share),
  card('Debit/Credit Card', Icons.credit_card),
  wallet('Wallet', Icons.account_balance_wallet),
  cashOnDelivery('Cash on Delivery', Icons.local_shipping);

  const PaymentMethod(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// State for payment method selection
class PaymentMethodState {
  const PaymentMethodState({
    this.selectedMethod = PaymentMethod.mpesa,
    this.isLoading = false,
    this.error,
  });

  final PaymentMethod selectedMethod;
  final bool isLoading;
  final String? error;

  PaymentMethodState copyWith({
    PaymentMethod? selectedMethod,
    bool? isLoading,
    String? error,
  }) {
    return PaymentMethodState(
      selectedMethod: selectedMethod ?? this.selectedMethod,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Controller for payment method selection
class PaymentMethodController extends StateNotifier<PaymentMethodState> {
  PaymentMethodController() : super(const PaymentMethodState());

  void selectMethod(PaymentMethod method) {
    state = state.copyWith(selectedMethod: method);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }
}

/// Provider for payment method selection
final paymentMethodProvider =
    StateNotifierProvider.autoDispose<PaymentMethodController, PaymentMethodState>(
  (ref) => PaymentMethodController(),
);

/// UI Widget for payment method selection
class PaymentMethodSelector extends ConsumerWidget {
  const PaymentMethodSelector({
    Key? key,
    this.onMethodSelected,
  }) : super(key: key);

  final void Function(PaymentMethod)? onMethodSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paymentMethodProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Payment Method',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...PaymentMethod.values.map(
          (method) => _PaymentMethodCard(
            method: method,
            isSelected: state.selectedMethod == method,
            onTap: () {
              ref.read(paymentMethodProvider.notifier).selectMethod(method);
              onMethodSelected?.call(method);
            },
          ),
        ),
        if (state.error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.error),
            ),
            child: Text(
              state.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ],
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surface,
      child: ListTile(
        leading: Icon(
          method.icon,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
        ),
        title: Text(
          method.label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        trailing: Radio<bool>(
          value: true,
          groupValue: isSelected,
          onChanged: (_) => onTap(),
          activeColor: Theme.of(context).colorScheme.primary,
        ),
        onTap: onTap,
      ),
    );
  }
}

/// Dialog to show payment method selection
Future<PaymentMethod?> showPaymentMethodDialog(BuildContext context) {
  return showDialog<PaymentMethod>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Select Payment Method'),
      content: SingleChildScrollView(
        child: PaymentMethodSelector(
          onMethodSelected: (method) => Navigator.pop(context, method),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}
