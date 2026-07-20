String formatPrice(
  double amount, {
  String currency = 'KES',
  int decimalPlaces = 2,
}) {
  return '$currency ${amount.toStringAsFixed(decimalPlaces)}';
}
