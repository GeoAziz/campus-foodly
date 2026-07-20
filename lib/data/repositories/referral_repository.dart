import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/referral.dart';

abstract class ReferralRepository {
  Future<ReferralCode?> getReferralCode(String userId);
  Future<ReferralCode> createReferralCode(String userId);
  Future<ReferralCode?> getReferralCodeByCode(String code);
  Future<void> recordReferral(String referrerId, String refereeId, String code);
}

class FirestoreReferralRepository implements ReferralRepository {
  FirestoreReferralRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<ReferralCode?> getReferralCode(String userId) async {
    try {
      final doc = await _firestore.collection('referral_codes').doc(userId).get();
      if (!doc.exists) return null;
      return ReferralCode.fromMap(doc.id, doc.data() ?? {});
    } catch (e) {
      return null;
    }
  }

  @override
  Future<ReferralCode> createReferralCode(String userId) async {
    final code = ReferralCode.create(userId);
    await _firestore
        .collection('referral_codes')
        .doc(userId)
        .set(code.toMap());
    return code;
  }

  @override
  Future<ReferralCode?> getReferralCodeByCode(String code) async {
    try {
      final snapshot = await _firestore
          .collection('referral_codes')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return ReferralCode.fromMap(
        snapshot.docs.first.id,
        snapshot.docs.first.data(),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> recordReferral(
    String referrerId,
    String refereeId,
    String code,
  ) async {
    const uuid = Uuid();
    final id = uuid.v4();

    await _firestore.collection('referral_records').doc(id).set({
      'referrer_id': referrerId,
      'referee_id': refereeId,
      'referral_code': code,
      'created_at': FieldValue.serverTimestamp(),
      'is_active': true,
    });

    // Increment referral count
    await _firestore
        .collection('referral_codes')
        .doc(referrerId)
        .update({
          'referral_count': FieldValue.increment(1),
          'points_earned': FieldValue.increment(50),
        });
  }
}

class MockReferralRepository implements ReferralRepository {
  @override
  Future<ReferralCode?> getReferralCode(String userId) async {
    return ReferralCode.create(userId);
  }

  @override
  Future<ReferralCode> createReferralCode(String userId) async {
    return ReferralCode.create(userId);
  }

  @override
  Future<ReferralCode?> getReferralCodeByCode(String code) async {
    return null;
  }

  @override
  Future<void> recordReferral(
    String referrerId,
    String refereeId,
    String code,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}

ReferralRepository buildReferralRepository() {
  return FirestoreReferralRepository(FirebaseFirestore.instance);
}
