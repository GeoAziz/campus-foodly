/// A single add-on / extra that can be attached to a menu item.
class MenuAddOn {
  const MenuAddOn({required this.name, required this.price});

  final String name;
  final double price;

  factory MenuAddOn.fromMap(Map<String, dynamic> data) {
    return MenuAddOn(
      name: data['name'] as String? ?? '',
      price: (data['price'] as num? ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'price': price};
}

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
    this.ingredients = const [],
    this.allergens = const [],
    this.dietary = const [],
    this.portion = '',
    this.prepTimeMins = 0,
    this.calories = 0,
    this.spiceLevel = 0,
    this.addOns = const [],
    this.isPopular = false,
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

  /// Named ingredients that make up the dish.
  final List<String> ingredients;

  /// Allergen warnings (e.g. Gluten, Dairy, Nuts, Egg, Fish).
  final List<String> allergens;

  /// Dietary tags (e.g. Vegetarian, Vegan, Halal, Gluten-Free).
  final List<String> dietary;

  /// Human-readable portion size (e.g. "Serves 1", "300g", "500ml").
  final String portion;

  /// Typical preparation time in minutes (0 when unknown).
  final int prepTimeMins;

  /// Approximate energy content in kcal (0 when unknown).
  final int calories;

  /// Spice level from 0 (none) to 3 (very hot).
  final int spiceLevel;

  /// Optional paid extras that can be added to the item.
  final List<MenuAddOn> addOns;

  /// Whether the item is flagged as a popular / best-seller pick.
  final bool isPopular;

  factory MenuItem.fromMap(String id, Map<String, dynamic> data) {
    final foodTypes = (data['foodTypes'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList(growable: false);

    List<String> stringList(String key) =>
        (data[key] as List<dynamic>? ?? const [])
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
      ingredients: stringList('ingredients'),
      allergens: stringList('allergens'),
      dietary: stringList('dietary'),
      portion: data['portion'] as String? ?? '',
      prepTimeMins: (data['prepTimeMins'] as num? ?? 0).toInt(),
      calories: (data['calories'] as num? ?? 0).toInt(),
      spiceLevel: (data['spiceLevel'] as num? ?? 0).toInt(),
      addOns: (data['addOns'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MenuAddOn.fromMap)
          .toList(growable: false),
      isPopular: data['isPopular'] as bool? ?? false,
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
      'ingredients': ingredients,
      'allergens': allergens,
      'dietary': dietary,
      'portion': portion,
      'prepTimeMins': prepTimeMins,
      'calories': calories,
      'spiceLevel': spiceLevel,
      'addOns': addOns.map((a) => a.toMap()).toList(),
      'isPopular': isPopular,
    };
  }
}
