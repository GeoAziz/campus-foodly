class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    required this.image,
    required this.location,
    required this.rating,
    required this.deliveryTime,
    this.ratingCount = 0,
    this.deliveryFee = 'Free',
    this.categories = const [],
    this.dietaries = const [],
    this.priceTier = 3,
    this.isFeatured = false,
    this.campusId,
    this.phone,
    this.isOpen = true,
    this.opensAt,
    this.closesAt,
    this.description,
  });

  final String id;
  final String name;
  final String image;
  final String location;
  final double rating;
  final int deliveryTime;
  final int ratingCount;
  final String deliveryFee;
  final List<String> categories;
  final List<String> dietaries;
  final int priceTier;
  final bool isFeatured;
  final String? campusId;
  final String? phone;
  final bool isOpen;
  final String? opensAt;
  final String? closesAt;
  final String? description;

  factory Restaurant.fromMap(String id, Map<String, dynamic> data) {
    final categories =
        ((data['categories'] ?? data['foodTypes']) as List<dynamic>? ??
                const [])
            .map((item) => item.toString())
            .toList(growable: false);

    return Restaurant(
      id: id,
      name: data['name'] as String? ?? '',
      image: data['image'] as String? ?? '',
      location: data['location'] as String? ?? 'San Francisco',
      rating: (data['rating'] as num? ?? 0).toDouble(),
      deliveryTime: (data['deliveryTime'] as num? ?? 0).toInt(),
      ratingCount: (data['ratingCount'] as num? ?? 0).toInt(),
      deliveryFee: data['deliveryFee'] as String? ?? 'Free',
      categories: categories,
      dietaries: (data['dietaries'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      priceTier: (data['priceTier'] as num? ?? 3).toInt(),
      isFeatured: data['isFeatured'] as bool? ?? false,
      campusId: data['campusId'] as String?,
      phone: data['phone'] as String?,
      isOpen: data['is_open'] as bool? ?? true,
      opensAt: data['opens_at'] as String?,
      closesAt: data['closes_at'] as String?,
      description: data['description'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'image': image,
      'location': location,
      'rating': rating,
      'deliveryTime': deliveryTime,
      'ratingCount': ratingCount,
      'deliveryFee': deliveryFee,
      'categories': categories,
      'dietaries': dietaries,
      'priceTier': priceTier,
      'isFeatured': isFeatured,
      'campusId': campusId,
      'phone': phone,
      'is_open': isOpen,
      'opens_at': opensAt,
      'closes_at': closesAt,
      'description': description,
    };
  }
}
