import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_item.dart';
import '../models/menu_item.dart';

final cartProvider = StateNotifierProvider<CartController, List<CartItem>>(
  (ref) => CartController(),
);

class CartController extends StateNotifier<List<CartItem>> {
  CartController() : super(const []);

  void addItem(
    MenuItem menuItem, {
    int quantity = 1,
    String? specialInstructions,
  }) {
    final sanitizedQuantity = quantity < 1 ? 1 : quantity;
    final existingIndex = state.indexWhere(
      (item) =>
          item.menuItem.id == menuItem.id &&
          item.specialInstructions == specialInstructions,
    );

    if (existingIndex == -1) {
      state = [
        ...state,
        CartItem(
          id: 'cart_${DateTime.now().microsecondsSinceEpoch}',
          menuItem: menuItem,
          quantity: sanitizedQuantity,
          specialInstructions: specialInstructions,
        ),
      ];
      return;
    }

    final existingItem = state[existingIndex];
    final updatedItems = [...state];
    updatedItems[existingIndex] = existingItem.copyWith(
      quantity: existingItem.quantity + sanitizedQuantity,
    );
    state = updatedItems;
  }

  void incrementQuantity(String cartItemId) {
    state = state
        .map(
          (item) => item.id == cartItemId
              ? item.copyWith(quantity: item.quantity + 1)
              : item,
        )
        .toList(growable: false);
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
  }

  void removeItem(String cartItemId) {
    state =
        state.where((item) => item.id != cartItemId).toList(growable: false);
  }

  void clear() {
    state = const [];
  }

  double get subtotal => state.fold(0, (sum, item) => sum + item.totalPrice);
}
