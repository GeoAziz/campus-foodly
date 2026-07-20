class Voucher {
  const Voucher({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.minOrder,
    required this.expiresAt,
    required this.isUsed,
    this.userId,
    this.reason,
    this.createdAt,
  });

  final String id;
  final String code;
  final String discountType; // "percentage" or "fixed"
  final double discountValue;
  final double minOrder;
  final DateTime expiresAt;
  final bool isUsed;
  final String? userId; // null = public voucher
  final String? reason; // "late_order", "referral", "loyalty"
  final DateTime? createdAt;

  factory Voucher.fromMap(String id, Map<String, dynamic> data) {
    return Voucher(
      id: id,
      code: data['code'] as String? ?? '',
      discountType: data['discount_type'] as String? ?? 'fixed',
      discountValue: (data['discount_value'] as num? ?? 0).toDouble(),
      minOrder: (data['min_order'] as num? ?? 0).toDouble(),
      expiresAt: (data['expires_at'] as DateTime?) ?? DateTime.now().add(const Duration(days: 30)),
      isUsed: data['is_used'] as bool? ?? false,
      userId: data['user_id'] as String?,
      reason: data['reason'] as String?,
      createdAt: data['created_at'] as DateTime?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'discount_type': discountType,
      'discount_value': discountValue,
      'min_order': minOrder,
      'expires_at': expiresAt,
      'is_used': isUsed,
      'user_id': userId,
      'reason': reason,
      'created_at': createdAt,
    };
  }

  bool isExpired() => DateTime.now().isAfter(expiresAt);
  bool isValid() => !isUsed && !isExpired();

  double calculateDiscount(double orderAmount) {
    if (orderAmount < minOrder) return 0;
    if (discountType == 'percentage') {
      return (orderAmount * discountValue) / 100;
    }
    return discountValue;
  }

  Voucher markAsUsed() {
    return Voucher(
      id: id,
      code: code,
      discountType: discountType,
      discountValue: discountValue,
      minOrder: minOrder,
      expiresAt: expiresAt,
      isUsed: true,
      userId: userId,
      reason: reason,
      createdAt: createdAt,
    );
  }
}
