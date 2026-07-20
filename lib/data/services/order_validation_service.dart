import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../models/cart_item.dart';

final _logger = Logger();

/// Configuration for order validation rules
class OrderValidationConfig {
  const OrderValidationConfig({
    this.amountTolerance = 0.01,
    this.minimumOrderAmount = 0.0,
    this.minimumItems = 1,
  });

  final double amountTolerance;
  final double minimumOrderAmount;
  final int minimumItems;
}

/// Validates order amounts and cart consistency
class OrderValidationService {
  static OrderValidationConfig _config = const OrderValidationConfig();

  /// Update validation configuration
  static void setConfig(OrderValidationConfig config) {
    _config = config;
    _logger.d(
      'OrderValidationConfig updated: '
      'tolerance=${config.amountTolerance}, '
      'minOrder=${config.minimumOrderAmount}, '
      'minItems=${config.minimumItems}',
    );
  }

  /// Validate that the checkout amount matches the cart items total
  /// Returns true if valid, false otherwise
  static bool validateCheckoutAmount({
    required List<CartItem> cartItems,
    required double checkoutAmount,
    double? tolerance,
  }) {
    if (cartItems.isEmpty) {
      _logger.d('[OrderValidation] Cannot validate empty cart');
      return false;
    }

    final amountTolerance = tolerance ?? _config.amountTolerance;

    final calculatedTotal = cartItems.fold<double>(
      0,
      (sum, item) => sum + item.totalPrice,
    );

    final difference = (checkoutAmount - calculatedTotal).abs();
    final isValid = difference <= amountTolerance;

    _logger.d(
      '[OrderValidation] Checkout amount: $checkoutAmount, '
      'Calculated total: $calculatedTotal, '
      'Difference: $difference, Tolerance: $amountTolerance, Valid: $isValid',
    );

    return isValid;
  }

  /// Validate minimum order amount
  static bool validateMinimumOrderAmount({
    required double checkoutAmount,
    double? minimumAmount,
  }) {
    final minAmount = minimumAmount ?? _config.minimumOrderAmount;
    final isValid = checkoutAmount >= minAmount;

    if (!isValid) {
      _logger.d(
        '[OrderValidation] Order amount $checkoutAmount below minimum $minAmount',
      );
    }

    return isValid;
  }

  /// Validate all items are from the same restaurant
  static bool validateSingleRestaurant(List<CartItem> cartItems) {
    if (cartItems.isEmpty) return true;

    final firstRestaurantId = cartItems.first.menuItem.restaurantId;
    final allSameRestaurant = cartItems
        .every((item) => item.menuItem.restaurantId == firstRestaurantId);

    if (!allSameRestaurant) {
      _logger.d('[OrderValidation] Items from different restaurants detected');
    }

    return allSameRestaurant;
  }

  /// Validate cart has minimum required items
  static bool validateMinimumItems(
    List<CartItem> cartItems, {
    int? minimum,
  }) {
    final minItems = minimum ?? _config.minimumItems;
    final totalItems =
        cartItems.fold<int>(0, (sum, item) => sum + item.quantity);
    final isValid = totalItems >= minItems;

    if (!isValid) {
      _logger.d(
        '[OrderValidation] Minimum $minItems items required, got $totalItems',
      );
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
      _logger.d('[OrderValidation] Invalid delivery address');
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

    if (!validateCheckoutAmount(
        cartItems: cartItems, checkoutAmount: checkoutAmount)) {
      errors.add('Order amount does not match cart items');
    }

    if (!validateMinimumOrderAmount(checkoutAmount: checkoutAmount)) {
      errors.add(
        'Minimum order amount is ${_config.minimumOrderAmount}',
      );
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
