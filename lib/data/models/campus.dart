class Campus {
  const Campus({
    required this.id,
    required this.name,
    required this.shortName,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.isActive,
    this.deliveryFee = 0,
    this.minOrder = 0,
    this.imageUrl,
    this.description,
  });

  final String id;
  final String name;
  final String shortName;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final bool isActive;
  final double deliveryFee;
  final double minOrder;
  final String? imageUrl;
  final String? description;

  factory Campus.fromMap(String id, Map<String, dynamic> data) {
    return Campus(
      id: id,
      name: data['name'] as String? ?? '',
      shortName: data['short_name'] as String? ?? '',
      latitude: (data['latitude'] as num? ?? 0).toDouble(),
      longitude: (data['longitude'] as num? ?? 0).toDouble(),
      radiusMeters: (data['radius_meters'] as num? ?? 800).toInt(),
      isActive: data['is_active'] as bool? ?? true,
      deliveryFee: (data['delivery_fee'] as num? ?? 0).toDouble(),
      minOrder: (data['min_order'] as num? ?? 0).toDouble(),
      imageUrl: data['image_url'] as String?,
      description: data['description'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'short_name': shortName,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meters': radiusMeters,
      'is_active': isActive,
      'delivery_fee': deliveryFee,
      'min_order': minOrder,
      'image_url': imageUrl,
      'description': description,
    };
  }

  Campus copyWith({
    String? id,
    String? name,
    String? shortName,
    double? latitude,
    double? longitude,
    int? radiusMeters,
    bool? isActive,
    double? deliveryFee,
    double? minOrder,
    String? imageUrl,
    String? description,
  }) {
    return Campus(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      isActive: isActive ?? this.isActive,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      minOrder: minOrder ?? this.minOrder,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
    );
  }
}
