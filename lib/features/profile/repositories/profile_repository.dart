import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/address.dart';
import '../models/notification_preference.dart';
import '../models/payment_method.dart';
import '../models/profile_data.dart';
import '../models/social_account.dart';

abstract class ProfileRepository {
  Future<ProfileData?> getProfile(String uid);

  Future<void> updateProfile(String uid, ProfileData profile);

  Future<List<Address>> getAddresses(String uid);

  Future<void> addAddress(String uid, Address address);

  Future<void> updateAddress(String uid, Address address);

  Future<void> deleteAddress(String uid, String addressId);

  Future<List<PaymentMethod>> getPaymentMethods(String uid);

  Future<void> addPaymentMethod(String uid, PaymentMethod method);

  Future<void> updatePaymentMethod(String uid, PaymentMethod method);

  Future<void> deletePaymentMethod(String uid, String paymentId);

  Future<NotificationPreference?> getNotificationPreferences(String uid);

  Future<void> updateNotificationPreferences(
    String uid,
    NotificationPreference prefs,
  );

  Future<List<SocialAccount>> getSocialAccounts(String uid);

  Future<void> linkSocialAccount(String uid, SocialAccount account);

  Future<void> unlinkSocialAccount(String uid, String provider);
}

class FirestoreProfileRepository implements ProfileRepository {
  FirestoreProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;

  // ===== Profile Data =====
  Future<ProfileData?> getProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        return null;
      }
      return ProfileData.fromMap(doc.data() ?? {});
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateProfile(String uid, ProfileData profile) async {
    try {
      await _firestore.collection('users').doc(uid).update(profile.toMap());
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ===== Addresses =====
  Future<List<Address>> getAddresses(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .get();

      return snapshot.docs
          .map((doc) => Address.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> addAddress(String uid, Address address) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .doc(address.id)
          .set(address.toMap());
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateAddress(String uid, Address address) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .doc(address.id)
          .update(address.toMap());
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteAddress(String uid, String addressId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .doc(addressId)
          .delete();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ===== Payment Methods =====
  Future<List<PaymentMethod>> getPaymentMethods(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('paymentMethods')
          .get();

      return snapshot.docs
          .map((doc) => PaymentMethod.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> addPaymentMethod(String uid, PaymentMethod method) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('paymentMethods')
          .doc(method.id)
          .set(method.toMap());
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updatePaymentMethod(String uid, PaymentMethod method) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('paymentMethods')
          .doc(method.id)
          .update(method.toMap());
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deletePaymentMethod(String uid, String paymentId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('paymentMethods')
          .doc(paymentId)
          .delete();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ===== Notification Preferences =====
  Future<NotificationPreference?> getNotificationPreferences(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('notifications')
          .get();

      if (!doc.exists) {
        return const NotificationPreference();
      }
      return NotificationPreference.fromMap(doc.data() ?? {});
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateNotificationPreferences(
    String uid,
    NotificationPreference prefs,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('notifications')
          .set(prefs.toMap());
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ===== Social Accounts =====
  Future<List<SocialAccount>> getSocialAccounts(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        return [];
      }

      final socialAccounts = doc.data()?['socialAccounts'] as List<dynamic>?;
      if (socialAccounts == null) {
        return [];
      }

      return socialAccounts
          .map((item) => SocialAccount.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> linkSocialAccount(
    String uid,
    SocialAccount account,
  ) async {
    try {
      final userDoc = _firestore.collection('users').doc(uid);
      final doc = await userDoc.get();
      final socialAccounts = doc.data()?['socialAccounts'] as List<dynamic>?;
      final updated = (socialAccounts ?? const [])
          .where((item) =>
              (item as Map<String, dynamic>)['provider'] != account.provider)
          .map((item) => item as Map<String, dynamic>)
          .toList();

      updated.add(account.toMap());

      await userDoc.set({
        'socialAccounts': updated,
      }, SetOptions(merge: true));
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> unlinkSocialAccount(
    String uid,
    String provider,
  ) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return;

      final socialAccounts = doc.data()?['socialAccounts'] as List<dynamic>?;
      if (socialAccounts == null) return;

      final updated = socialAccounts
          .where((account) =>
              (account as Map<String, dynamic>)['provider'] != provider)
          .toList();

      await _firestore.collection('users').doc(uid).update({
        'socialAccounts': updated,
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ===== Utility =====
  Exception _handleError(dynamic error) {
    if (error is FirebaseException) {
      return Exception('Firestore Error: ${error.message}');
    }
    return Exception('Profile Error: $error');
  }
}
