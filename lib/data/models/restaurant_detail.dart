class RestaurantDetail {
  const RestaurantDetail({
    required this.id,
    required this.restaurantId,
    this.foodTypes = const [],
    this.ratingCount = 0,
    this.deliveryFee = 'Free',
    this.deliveryTime = 25,
    this.takeAwayLabel = 'Take away',
  });

  final String id;
  final String restaurantId;
  final List<String> foodTypes;
  final int ratingCount;
  final String deliveryFee;
  final int deliveryTime;
  final String takeAwayLabel;

  factory RestaurantDetail.fromMap(String id, Map<String, dynamic> data) {
    final payload = (data['data'] is Map<String, dynamic>)
        ? data['data'] as Map<String, dynamic>
        : data;

    final rawFoodTypes = payload['foodTypes'] ?? payload['foodType'];

    return RestaurantDetail(
      id: id,
      restaurantId: data['restaurantId'] as String? ??
          payload['restaurantId'] as String? ??
          '',
      foodTypes: (rawFoodTypes as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      ratingCount: (payload['ratingCount'] as num? ?? 0).toInt(),
      deliveryFee: payload['deliveryFee'] as String? ?? 'Free',
      deliveryTime: (payload['deliveryTime'] as num? ?? 25).toInt(),
      takeAwayLabel: payload['takeAwayLabel'] as String? ?? 'Take away',
    );
  }
}