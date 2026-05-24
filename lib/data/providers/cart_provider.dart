import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/cart_item.dart';
import '../models/menu_item.dart';
import '../services/cart_persistence_service.dart';

// Provider for the CartPersistenceService
final cartPersistenceProvider =
    FutureProvider<CartPersistenceService>((ref) async {
  return CartPersistenceService.create();
});

final cartProvider = StateNotifierProvider<CartController, List<CartItem>>(
  (ref) => CartController(ref),
);

class CartController extends StateNotifier<List<CartItem>> {
  CartController(this._ref) : super(const []);

  final Ref _ref;
  CartPersistenceService? _persistence;
  bool _isInitialized = false;

  /// Initialize cart by loading persisted data
  Future<void> initializeCart() async {
    if (_isInitialized) return;

    try {
      _persistence = await _ref.read(cartPersistenceProvider.future);
      final persistedItems = await _persistence!.loadCart();
      state = persistedItems;
      _isInitialized = true;
      debugPrint('[CartController] Initialized with ${persistedItems.length} items');
    } catch (e) {
      debugPrint('[CartController] Error initializing cart: $e');
      _isInitialized = true;
    }
  }

  /// Persist the current cart state
  Future<void> _persistCart() async {
    try {
      _persistence ??= await _ref.read(cartPersistenceProvider.future);
      await _persistence!.saveCart(state);
    } catch (e) {
      debugPrint('[CartController] Error persisting cart: $e');
    }
  }

  /// Add item to cart with cross-restaurant validation
  void addItem(
    MenuItem menuItem, {
    int quantity = 1,
    String? specialInstructions,
  }) {
    final sanitizedQuantity = quantity < 1 ? 1 : quantity;

    // Check if adding items from a different restaurant
    if (state.isNotEmpty) {
      final firstItemRestaurantId = state.first.menuItem.restaurantId;
      if (menuItem.restaurantId != firstItemRestaurantId) {
        throw StateError(
          'Cannot add items from different restaurants. '
          'Clear your cart to order from another restaurant.',
        );
      }
    }

    // Check for duplicate item with same customization
    final existingIndex = state.indexWhere(
      (item) =>
          item.menuItem.id == menuItem.id &&
          item.specialInstructions == specialInstructions,
    );

    if (existingIndex == -1) {
      // Generate UUID-based ID for better collision prevention
      final cartItemId = 'cart_${const Uuid().v4()}';
      state = [
        ...state,
        CartItem(
          id: cartItemId,
          menuItem: menuItem,
          quantity: sanitizedQuantity,
          specialInstructions: specialInstructions,
        ),
      ];
    } else {
      final existingItem = state[existingIndex];
      final updatedItems = [...state];
      updatedItems[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + sanitizedQuantity,
      );
      state = updatedItems;
    }

    // Persist after adding
    _persistCart();
  }

  void incrementQuantity(String cartItemId) {
    state = state
        .map(
          (item) => item.id == cartItemId
              ? item.copyWith(quantity: item.quantity + 1)
              : item,
        )
        .toList(growable: false);
    _persistCart();
  }

  void decrementQuantity(String cartItemId) {
    final updatedItems = state
        .map((item) {
          if (item.id != cartItemId) {
            return item;
          }

          final nextQuantity = item.quantity - 1;
          if (nextQuantity <= 0) {
            return null;
          }

          return item.copyWith(quantity: nextQuantity);
        })
        .whereType<CartItem>()
        .toList(growable: false);

    state = updatedItems;
    _persistCart();
  }

  void removeItem(String cartItemId) {
    state =
        state.where((item) => item.id != cartItemId).toList(growable: false);
    _persistCart();
  }

  /// Clear cart (typically on logout or explicit user action)
  Future<void> clear() async {
    state = const [];
    try {
      _persistence ??= await _ref.read(cartPersistenceProvider.future);
      await _persistence!.clearCart();
      debugPrint('[CartController] Cart cleared');
    } catch (e) {
      debugPrint('[CartController] Error clearing persisted cart: $e');
    }
  }

  /// Get the restaurant ID of items in the cart (or null if empty)
  String? get restaurantId => state.isEmpty ? null : state.first.menuItem.restaurantId;

  double get subtotal => state.fold(0, (sum, item) => sum + item.totalPrice);
}
