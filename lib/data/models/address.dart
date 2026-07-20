class Address {
  const Address({
    required this.id,
    required this.label,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
    this.notes,
  });

  final String id;
  final String label; // e.g., "Home", "Work", "Dorm"
  final String address; // Full address string
  final double latitude;
  final double longitude;
  final bool isDefault;
  final String? notes;

  factory Address.fromMap(String id, Map<String, dynamic> data) {
    return Address(
      id: id,
      label: data['label'] as String? ?? 'Address',
      address: data['address'] as String? ?? '',
      latitude: (data['latitude'] as num? ?? 0).toDouble(),
      longitude: (data['longitude'] as num? ?? 0).toDouble(),
      isDefault: data['is_default'] as bool? ?? false,
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'is_default': isDefault,
      'notes': notes,
    };
  }

  Address copyWith({
    String? id,
    String? label,
    String? address,
    double? latitude,
    double? longitude,
    bool? isDefault,
    String? notes,
  }) {
    return Address(
      id: id ?? this.id,
      label: label ?? this.label,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() => '$label: $address ($latitude, $longitude)';
}
