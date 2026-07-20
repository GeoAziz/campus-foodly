import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/voucher.dart';

abstract class VoucherRepository {
  Future<Voucher?> getVoucherByCode(String code);
  Future<List<Voucher>> getUserVouchers(String userId);
  Future<void> createVoucher(Voucher voucher);
  Future<void> markVoucherAsUsed(String voucherId);
}

class FirestoreVoucherRepository implements VoucherRepository {
  FirestoreVoucherRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<Voucher?> getVoucherByCode(String code) async {
    try {
      final snapshot = await _firestore
          .collection('vouchers')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return Voucher.fromMap(snapshot.docs.first.id, snapshot.docs.first.data());
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Voucher>> getUserVouchers(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('vouchers')
          .where('user_id', isEqualTo: userId)
          .where('is_used', isEqualTo: false)
          .get();

      return snapshot.docs
          .map((doc) => Voucher.fromMap(doc.id, doc.data()))
          .where((v) => !v.isExpired())
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> createVoucher(Voucher voucher) async {
    await _firestore.collection('vouchers').doc(voucher.id).set(voucher.toMap());
  }

  @override
  Future<void> markVoucherAsUsed(String voucherId) async {
    await _firestore
        .collection('vouchers')
        .doc(voucherId)
        .update({'is_used': true});
  }
}

class VoucherService {
  static String generateVoucherCode() {
    const uuid = Uuid();
    return uuid.v4().substring(0, 8).toUpperCase();
  }

  static Voucher createLateOrderVoucher({
    required String userId,
    required int discountPercentage,
  }) {
    const uuid = Uuid();
    return Voucher(
      id: uuid.v4(),
      code: generateVoucherCode(),
      discountType: 'percentage',
      discountValue: discountPercentage.toDouble(),
      minOrder: 0,
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      isUsed: false,
      userId: userId,
      reason: 'late_order',
      createdAt: DateTime.now(),
    );
  }

  static Voucher createReferralVoucher({
    required String userId,
  }) {
    const uuid = Uuid();
    return Voucher(
      id: uuid.v4(),
      code: generateVoucherCode(),
      discountType: 'fixed',
      discountValue: 50, // KES 50
      minOrder: 100, // Min order KES 100
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      isUsed: false,
      userId: userId,
      reason: 'referral',
      createdAt: DateTime.now(),
    );
  }

  static Voucher createLoyaltyVoucher({
    required String userId,
  }) {
    const uuid = Uuid();
    return Voucher(
      id: uuid.v4(),
      code: generateVoucherCode(),
      discountType: 'fixed',
      discountValue: 50, // KES 50
      minOrder: 100,
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      isUsed: false,
      userId: userId,
      reason: 'loyalty',
      createdAt: DateTime.now(),
    );
  }
}
