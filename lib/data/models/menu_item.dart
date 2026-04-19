class MenuItem {
  const MenuItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.price,
    required this.image,
    this.description = '',
    this.category = '',
    this.foodType = '',
    this.priceRange = '',
    this.isAvailable = true,
  });

  final String id;
  final String restaurantId;
  final String name;
  final double price;
  final String image;
  final String description;
  final String category;
  final String foodType;
  final String priceRange;
  final bool isAvailable;

  factory MenuItem.fromMap(String id, Map<String, dynamic> data) {
    final foodTypes = (data['foodTypes'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList(growable: false);

    return MenuItem(
      id: id,
      restaurantId: data['restaurantId'] as String? ?? '',
      name: data['name'] as String? ?? data['title'] as String? ?? '',
      price: (data['price'] as num? ?? 0).toDouble(),
      image: data['image'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? '',
      foodType: data['foodType'] as String? ??
          (foodTypes.isNotEmpty ? foodTypes.first : ''),
      priceRange: data['priceRange'] as String? ?? '',
      isAvailable: data['isAvailable'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'name': name,
      'price': price,
      'image': image,
      'description': description,
      'category': category,
      'foodType': foodType,
      'priceRange': priceRange,
      'isAvailable': isAvailable,
    };
  }
}
