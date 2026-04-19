class Address {
  const Address({
    required this.id,
    required this.label,
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    this.country = 'US',
    this.isDefault = false,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String label; // e.g., 'Home', 'Work', 'Other'
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final bool isDefault;
  final double? latitude;
  final double? longitude;

  factory Address.fromMap(Map<String, dynamic> map, String id) {
    return Address(
      id: id,
      label: map['label'] as String? ?? 'Address',
      street: map['street'] as String,
      city: map['city'] as String,
      state: map['state'] as String,
      zipCode: map['zipCode'] as String,
      country: map['country'] as String? ?? 'US',
      isDefault: map['isDefault'] as bool? ?? false,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'isDefault': isDefault,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  Address copyWith({
    String? id,
    String? label,
    String? street,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    bool? isDefault,
    double? latitude,
    double? longitude,
  }) {
    return Address(
      id: id ?? this.id,
      label: label ?? this.label,
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      country: country ?? this.country,
      isDefault: isDefault ?? this.isDefault,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  String get formattedAddress => '$street, $city, $state $zipCode';
}
