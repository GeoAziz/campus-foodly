import 'package:uuid/uuid.dart';

class ReferralCode {
  const ReferralCode({
    required this.id,
    required this.userId,
    required this.code,
    required this.createdAt,
    this.referralCount = 0,
    this.pointsEarned = 0,
  });

  final String id;
  final String userId;
  final String code;
  final DateTime createdAt;
  final int referralCount;
  final int pointsEarned;

  static const int pointsPerReferral = 50;
  static const int minPointsEarnedForReferrer = 50;

  factory ReferralCode.create(String userId) {
    // Generate a unique referral code
    const uuid = Uuid();
    final randomPart = uuid.v4().substring(0, 8).toUpperCase();
    final code = 'FOODLY$randomPart';

    return ReferralCode(
      id: uuid.v4(),
      userId: userId,
      code: code,
      createdAt: DateTime.now(),
    );
  }

  factory ReferralCode.fromMap(String id, Map<String, dynamic> data) {
    return ReferralCode(
      id: id,
      userId: data['user_id'] as String? ?? '',
      code: data['code'] as String? ?? '',
      createdAt: (data['created_at'] as DateTime?) ?? DateTime.now(),
      referralCount: (data['referral_count'] as num? ?? 0).toInt(),
      pointsEarned: (data['points_earned'] as num? ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'code': code,
      'created_at': createdAt,
      'referral_count': referralCount,
      'points_earned': pointsEarned,
    };
  }

  ReferralCode addReferral() {
    return ReferralCode(
      id: id,
      userId: userId,
      code: code,
      createdAt: createdAt,
      referralCount: referralCount + 1,
      pointsEarned: pointsEarned + pointsPerReferral,
    );
  }
}

class ReferralRecord {
  const ReferralRecord({
    required this.id,
    required this.referrerId,
    required this.refereeId,
    required this.referralCode,
    required this.createdAt,
    this.isActive = true,
    this.pointsAwardedAt,
  });

  final String id;
  final String referrerId;
  final String refereeId;
  final String referralCode;
  final DateTime createdAt;
  final bool isActive;
  final DateTime? pointsAwardedAt;

  factory ReferralRecord.fromMap(String id, Map<String, dynamic> data) {
    return ReferralRecord(
      id: id,
      referrerId: data['referrer_id'] as String? ?? '',
      refereeId: data['referee_id'] as String? ?? '',
      referralCode: data['referral_code'] as String? ?? '',
      createdAt: (data['created_at'] as DateTime?) ?? DateTime.now(),
      isActive: data['is_active'] as bool? ?? true,
      pointsAwardedAt: data['points_awarded_at'] as DateTime?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'referrer_id': referrerId,
      'referee_id': refereeId,
      'referral_code': referralCode,
      'created_at': createdAt,
      'is_active': isActive,
      'points_awarded_at': pointsAwardedAt,
    };
  }

  bool isEligibleForReward() => isActive && pointsAwardedAt == null;
}
