class OrderItem {
  const OrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  final String id;
  final String name;
  final int quantity;
  final double unitPrice;

  double get totalPrice => unitPrice * quantity;

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      quantity: (data['quantity'] as num? ?? 0).toInt(),
      unitPrice: (data['unitPrice'] as num? ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }
}
