import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_service.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _currentUserId;

  static Future<void> initialize() async {
    if (!FirebaseService.isInitialized) {
      return;
    }

    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    _messaging.onTokenRefresh.listen((token) async {
      final userId = _currentUserId;
      if (userId == null || token.isEmpty) {
        return;
      }
      await _persistToken(userId, token);
    });
  }

  static Future<void> syncTokenForUser(String userId) async {
    if (!FirebaseService.isInitialized) {
      return;
    }

    _currentUserId = userId;
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    await _persistToken(userId, token);
  }

  static Future<void> clearSyncedUser() async {
    _currentUserId = null;
  }

  static Future<void> _persistToken(String userId, String token) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('fcmTokens')
          .doc(token)
          .set({
        'token': token,
        'updatedAt': FieldValue.serverTimestamp(),
        'platform': 'flutter',
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        debugPrint(
          'Notification token sync skipped due to Firestore permissions.',
        );
        return;
      }
      rethrow;
    }
  }
}
