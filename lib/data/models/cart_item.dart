import 'menu_item.dart';

class CartItem {
  const CartItem({
    required this.id,
    required this.menuItem,
    required this.quantity,
    this.specialInstructions,
  });

  final String id;
  final MenuItem menuItem;
  final int quantity;
  final String? specialInstructions;

  double get totalPrice => menuItem.price * quantity;

  CartItem copyWith({
    String? id,
    MenuItem? menuItem,
    int? quantity,
    String? specialInstructions,
  }) {
    return CartItem(
      id: id ?? this.id,
      menuItem: menuItem ?? this.menuItem,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }

  factory CartItem.fromMap(Map<String, dynamic> data) {
    final menuItemData = data['menuItem'] as Map<String, dynamic>? ?? const {};
    return CartItem(
      id: data['id'] as String? ?? '',
      menuItem: MenuItem.fromMap(
        (menuItemData['id'] as String?) ?? '',
        menuItemData,
      ),
      quantity: (data['quantity'] as num? ?? 0).toInt(),
      specialInstructions: data['specialInstructions'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'menuItem': menuItem.toMap()..['id'] = menuItem.id,
      'quantity': quantity,
      'specialInstructions': specialInstructions,
    };
  }

  // JSON serialization methods for persistence
  Map<String, dynamic> toJson() => toMap();

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final menuItemData = json['menuItem'] as Map<String, dynamic>? ?? const {};
    return CartItem(
      id: json['id'] as String? ?? '',
      menuItem: MenuItem.fromMap(
        (menuItemData['id'] as String?) ?? '',
        menuItemData,
      ),
      quantity: (json['quantity'] as num? ?? 0).toInt(),
      specialInstructions: json['specialInstructions'] as String?,
    );
  }
}
