import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

import 'firebase_service.dart';

final _logger = Logger();

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _currentUserId;
  static GoRouter? _router;

  static void registerRouter(GoRouter router) {
    _router = router;
  }

  static void _navigateToOrder(RemoteMessage message) {
    final orderId = message.data['orderId'] as String?;
    if (orderId == null || orderId.isEmpty) return;
    _logger.d('Navigating to order: $orderId');
    _router?.go('/order-tracking/$orderId');
  }

  static Future<void> initialize() async {
    if (!FirebaseService.isInitialized) {
      _logger.w('Firebase not initialized. Skipping notification setup.');
      return;
    }

    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _logger.w('Notification permissions denied by user');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.authorized) {
        _logger.i('Notification permissions granted');
      }

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Foreground messages
      FirebaseMessaging.onMessage.listen((message) {
        _logger.d('[FCM] Foreground message: ${message.notification?.title}');
      });

      // User tapped notification while app was in background
      FirebaseMessaging.onMessageOpenedApp.listen(_navigateToOrder);

      // App was launched via notification (terminated state)
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _logger.d('App launched from notification');
        // Use WidgetsBinding to defer until after widget tree is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateToOrder(initialMessage);
        });
      }

      _messaging.onTokenRefresh.listen((token) async {
        final userId = _currentUserId;
        if (userId == null || token.isEmpty) {
          return;
        }
        await _persistToken(userId, token, maxRetries: 3);
      });

      _logger.i('NotificationService initialized');
    } catch (e) {
      _logger.e('Error initializing notifications: $e');
    }
  }

  static Future<void> syncTokenForUser(String userId) async {
    if (!FirebaseService.isInitialized) {
      _logger.w('Firebase not initialized. Skipping token sync.');
      return;
    }

    _currentUserId = userId;
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        _logger.w('Failed to get FCM token');
        return;
      }

      await _persistToken(userId, token, maxRetries: 3);
    } catch (error) {
      _logger.e('Error syncing notification token: $error');
    }
  }

  static Future<void> clearSyncedUser() async {
    _currentUserId = null;
    _logger.d('Cleared synced user');
  }

  /// Persist token with configurable retry
  static Future<void> _persistToken(
    String userId,
    String token, {
    int maxRetries = 1,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
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

        _logger.d('FCM token persisted for user: $userId');
        return;
      } on FirebaseException catch (error) {
        if (error.code == 'permission-denied') {
          _logger.w('Firestore permission denied for token sync');
          return;
        }

        attempts++;
        if (attempts < maxRetries) {
          _logger.d(
            'Token persistence failed (attempt $attempts/$maxRetries), retrying...',
          );
          await Future.delayed(Duration(milliseconds: 500 * attempts));
        } else {
          _logger.e('Failed to persist token after $maxRetries attempts: $error');
          rethrow;
        }
      } catch (error) {
        attempts++;
        if (attempts >= maxRetries) {
          _logger.e('Unexpected error persisting token: $error');
          rethrow;
        }
        await Future.delayed(Duration(milliseconds: 500 * attempts));
      }
    }
  }
}
