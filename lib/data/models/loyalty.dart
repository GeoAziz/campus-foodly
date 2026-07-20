class LoyaltyRecord {
  const LoyaltyRecord({
    required this.id,
    required this.userId,
    required this.pointsBalance,
    required this.pointsEarned,
    required this.pointsRedeemed,
    required this.lastUpdated,
    this.notes,
  });

  final String id;
  final String userId;
  final int pointsBalance;
  final int pointsEarned;
  final int pointsRedeemed;
  final DateTime lastUpdated;
  final String? notes;

  // Constants
  static const int pointsPerKes = 1; // 1 point per KES 10
  static const int pointsPerOrder = 10; // Base points per order
  static const int pointsForRedemption = 100; // Points needed for voucher
  static const int voucherValue = 50; // KES value of voucher

  factory LoyaltyRecord.fromMap(String id, Map<String, dynamic> data) {
    return LoyaltyRecord(
      id: id,
      userId: data['user_id'] as String? ?? '',
      pointsBalance: (data['points_balance'] as num? ?? 0).toInt(),
      pointsEarned: (data['points_earned'] as num? ?? 0).toInt(),
      pointsRedeemed: (data['points_redeemed'] as num? ?? 0).toInt(),
      lastUpdated: (data['last_updated'] as DateTime?) ?? DateTime.now(),
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'points_balance': pointsBalance,
      'points_earned': pointsEarned,
      'points_redeemed': pointsRedeemed,
      'last_updated': lastUpdated,
      'notes': notes,
    };
  }

  /// Calculate points from order amount
  static int calculatePoints(double orderAmount) {
    return (orderAmount ~/ 10) + pointsPerOrder;
  }

  /// Check if redemption is possible
  bool canRedeem() => pointsBalance >= pointsForRedemption;

  /// Get number of redeemable vouchers
  int getRedeemableVouchers() =>
      (pointsBalance / pointsForRedemption).floor();

  LoyaltyRecord copyWith({
    String? id,
    String? userId,
    int? pointsBalance,
    int? pointsEarned,
    int? pointsRedeemed,
    DateTime? lastUpdated,
    String? notes,
  }) {
    return LoyaltyRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      pointsBalance: pointsBalance ?? this.pointsBalance,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      pointsRedeemed: pointsRedeemed ?? this.pointsRedeemed,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      notes: notes ?? this.notes,
    );
  }
}
