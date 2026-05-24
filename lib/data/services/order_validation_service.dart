import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';

/// Validates order amounts and cart consistency
class OrderValidationService {
  /// Validate that the checkout amount matches the cart items total
  /// Returns true if valid, false otherwise
  static bool validateCheckoutAmount({
    required List<CartItem> cartItems,
    required double checkoutAmount,
    double tolerance = 0.01, // Allow for floating point errors
  }) {
    if (cartItems.isEmpty) {
      debugPrint('[OrderValidation] Cannot validate empty cart');
      return false;
    }

    final calculatedTotal = cartItems.fold<double>(
      0,
      (sum, item) => sum + item.totalPrice,
    );

    final difference = (checkoutAmount - calculatedTotal).abs();
    final isValid = difference <= tolerance;

    debugPrint(
      '[OrderValidation] Checkout amount: $checkoutAmount, '
      'Calculated total: $calculatedTotal, '
      'Difference: $difference, Valid: $isValid',
    );

    return isValid;
  }

  /// Validate all items are from the same restaurant
  static bool validateSingleRestaurant(List<CartItem> cartItems) {
    if (cartItems.isEmpty) return true;

    final firstRestaurantId = cartItems.first.menuItem.restaurantId;
    final allSameRestaurant =
        cartItems.every((item) => item.menuItem.restaurantId == firstRestaurantId);

    if (!allSameRestaurant) {
      debugPrint('[OrderValidation] Items from different restaurants detected');
    }

    return allSameRestaurant;
  }

  /// Validate cart has minimum required items
  static bool validateMinimumItems(List<CartItem> cartItems, {int minimum = 1}) {
    final totalItems = cartItems.fold<int>(0, (sum, item) => sum + item.quantity);
    final isValid = totalItems >= minimum;

    if (!isValid) {
      debugPrint('[OrderValidation] Minimum $minimum items required, got $totalItems');
    }

    return isValid;
  }

  /// Validate delivery address exists and is valid
  static bool validateDeliveryAddress({
    required String addressId,
    required String addressLine,
  }) {
    final isValid = addressId.isNotEmpty && addressLine.isNotEmpty;

    if (!isValid) {
      debugPrint('[OrderValidation] Invalid delivery address');
    }

    return isValid;
  }

  /// Comprehensive order validation
  static ValidationResult validateOrder({
    required List<CartItem> cartItems,
    required double checkoutAmount,
    required String deliveryAddressId,
    required String deliveryAddressLine,
  }) {
    final errors = <String>[];

    if (!validateMinimumItems(cartItems)) {
      errors.add('Your cart is empty');
    }

    if (!validateSingleRestaurant(cartItems)) {
      errors.add('All items must be from the same restaurant');
    }

    if (!validateCheckoutAmount(cartItems: cartItems, checkoutAmount: checkoutAmount)) {
      errors.add('Order amount does not match cart items');
    }

    if (!validateDeliveryAddress(
      addressId: deliveryAddressId,
      addressLine: deliveryAddressLine,
    )) {
      errors.add('Valid delivery address is required');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
}

class ValidationResult {
  const ValidationResult({
    required this.isValid,
    required this.errors,
  });

  final bool isValid;
  final List<String> errors;

  String get errorMessage => errors.join('\n');
}
