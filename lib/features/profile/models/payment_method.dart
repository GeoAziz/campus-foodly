class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.type, // 'card', 'paypal', 'apple_pay', 'google_pay'
    required this.label,
    this.last4,
    this.brand, // 'visa', 'mastercard', etc.
    this.expiryMonth,
    this.expiryYear,
    this.isDefault = false,
    this.tokenId, // Tokenized payment method reference
  });

  final String id;
  final String type;
  final String label;
  final String? last4;
  final String? brand;
  final int? expiryMonth;
  final int? expiryYear;
  final bool isDefault;
  final String? tokenId;

  factory PaymentMethod.fromMap(Map<String, dynamic> map, String id) {
    return PaymentMethod(
      id: id,
      type: map['type'] as String,
      label: map['label'] as String,
      last4: map['last4'] as String?,
      brand: map['brand'] as String?,
      expiryMonth: map['expiryMonth'] as int?,
      expiryYear: map['expiryYear'] as int?,
      isDefault: map['isDefault'] as bool? ?? false,
      tokenId: map['tokenId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'label': label,
      'last4': last4,
      'brand': brand,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'isDefault': isDefault,
      'tokenId': tokenId,
    };
  }

  PaymentMethod copyWith({
    String? id,
    String? type,
    String? label,
    String? last4,
    String? brand,
    int? expiryMonth,
    int? expiryYear,
    bool? isDefault,
    String? tokenId,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      last4: last4 ?? this.last4,
      brand: brand ?? this.brand,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      isDefault: isDefault ?? this.isDefault,
      tokenId: tokenId ?? this.tokenId,
    );
  }

  String get displayName {
    if (last4 != null && brand != null) {
      return '$brand ending in $last4';
    }
    return label;
  }
}
