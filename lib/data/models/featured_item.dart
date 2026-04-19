class FeaturedItem {
  const FeaturedItem({
    required this.id,
    required this.restaurantId,
    required this.title,
    required this.image,
    this.foodType = '',
    this.priceRange = '',
    this.position = 0,
  });

  final String id;
  final String restaurantId;
  final String title;
  final String image;
  final String foodType;
  final String priceRange;
  final int position;

  factory FeaturedItem.fromMap(String id, Map<String, dynamic> data) {
    final payload = (data['data'] is Map<String, dynamic>)
        ? data['data'] as Map<String, dynamic>
        : data;

    return FeaturedItem(
      id: id,
      restaurantId: data['restaurantId'] as String? ??
          payload['restaurantId'] as String? ??
          '',
      title: payload['title'] as String? ?? '',
      image: payload['image'] as String? ?? '',
      foodType: payload['foodType'] as String? ?? '',
      priceRange: payload['priceRange'] as String? ?? '',
      position: (payload['position'] as num? ?? 0).toInt(),
    );
  }
}