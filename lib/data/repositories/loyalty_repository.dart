import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/loyalty.dart';

abstract class LoyaltyRepository {
  Future<LoyaltyRecord?> getLoyaltyRecord(String userId);
  Future<void> addPoints(String userId, int points, String reason);
  Future<void> redeemPoints(String userId, int pointsToRedeem);
}

class FirestoreLoyaltyRepository implements LoyaltyRepository {
  FirestoreLoyaltyRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<LoyaltyRecord?> getLoyaltyRecord(String userId) async {
    try {
      final doc =
          await _firestore.collection('loyalty').doc(userId).get();
      if (!doc.exists) return null;
      return LoyaltyRecord.fromMap(doc.id, doc.data() ?? {});
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> addPoints(
    String userId,
    int points,
    String reason,
  ) async {
    final record = await getLoyaltyRecord(userId);

    if (record == null) {
      // Create new loyalty record
      await _firestore.collection('loyalty').doc(userId).set({
        'user_id': userId,
        'points_balance': points,
        'points_earned': points,
        'points_redeemed': 0,
        'last_updated': FieldValue.serverTimestamp(),
        'notes': reason,
      });
    } else {
      // Update existing record
      await _firestore.collection('loyalty').doc(userId).update({
        'points_balance': FieldValue.increment(points),
        'points_earned': FieldValue.increment(points),
        'last_updated': FieldValue.serverTimestamp(),
        'notes': reason,
      });
    }
  }

  @override
  Future<void> redeemPoints(String userId, int pointsToRedeem) async {
    final record = await getLoyaltyRecord(userId);
    if (record == null || record.pointsBalance < pointsToRedeem) {
      throw Exception('Insufficient loyalty points');
    }

    await _firestore.collection('loyalty').doc(userId).update({
      'points_balance': FieldValue.increment(-pointsToRedeem),
      'points_redeemed': FieldValue.increment(pointsToRedeem),
      'last_updated': FieldValue.serverTimestamp(),
    });
  }
}

class MockLoyaltyRepository implements LoyaltyRepository {
  @override
  Future<LoyaltyRecord?> getLoyaltyRecord(String userId) async {
    return LoyaltyRecord(
      id: userId,
      userId: userId,
      pointsBalance: 250,
      pointsEarned: 500,
      pointsRedeemed: 250,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Future<void> addPoints(
    String userId,
    int points,
    String reason,
  ) async {
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> redeemPoints(String userId, int pointsToRedeem) async {
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 500));
  }
}

LoyaltyRepository buildLoyaltyRepository() {
  return FirestoreLoyaltyRepository(FirebaseFirestore.instance);
}
