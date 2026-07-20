import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

final _logger = Logger();

/// Service for managing Firebase App Check
/// App Check helps protect backend resources from abuse by verifying requests from your app
class AppCheckService {
  static final AppCheckService _instance = AppCheckService._internal();

  bool _initialized = false;

  factory AppCheckService() {
    return _instance;
  }

  AppCheckService._internal();

  /// Initialize Firebase App Check with retry logic
  Future<void> initialize({int maxRetries = 3}) async {
    if (_initialized) return;

    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        // Use reCAPTCHA v3 for web, or device check for mobile
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.playIntegrity,
          appleProvider: AppleProvider.deviceCheck,
        );

        _logger.i('Firebase App Check initialized successfully');
        _initialized = true;
        return;
      } catch (e) {
        attempts++;
        _logger.w(
          'App Check initialization failed (attempt $attempts/$maxRetries): $e',
        );

        if (attempts < maxRetries) {
          await Future.delayed(Duration(seconds: attempts));
        } else {
          _logger.e(
            'App Check initialization failed after $maxRetries attempts. '
            'App will continue without App Check protection.',
          );
          // App Check is optional - the app can still function without it
          // but it's highly recommended for production
          return;
        }
      }
    }
  }

  /// Get App Check token with retry logic
  Future<String?> getToken({int maxRetries = 2}) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        final token = await FirebaseAppCheck.instance
            .getToken(forceRefresh: attempts > 0)
            .timeout(const Duration(seconds: 10));
        _logger.d('App Check token obtained');
        return token;
      } catch (e) {
        attempts++;
        _logger.w('App Check token request failed (attempt $attempts/$maxRetries): $e');

        if (attempts < maxRetries) {
          await Future.delayed(Duration(seconds: attempts));
        } else {
          _logger.e('Failed to get App Check token after $maxRetries attempts');
          return null;
        }
      }
    }

    return null;
  }

  /// Get limited use token for sensitive operations with retry
  /// Limited-use tokens have a restricted lifetime and can only be used once
  Future<String?> getLimitedUseToken({int maxRetries = 2}) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        final token = await FirebaseAppCheck.instance
            .getLimitedUseToken()
            .timeout(const Duration(seconds: 10));
        _logger.d('Limited use token obtained');
        return token;
      } catch (e) {
        attempts++;
        _logger.w(
          'Limited use token request failed (attempt $attempts/$maxRetries): $e',
        );

        if (attempts < maxRetries) {
          await Future.delayed(Duration(seconds: attempts));
        } else {
          _logger.e('Failed to get limited use token after $maxRetries attempts');
          return null;
        }
      }
    }

    return null;
  }

  /// Check if App Check is initialized and available
  bool get isInitialized => _initialized;

  /// Get current platform
  String get currentPlatform {
    if (kIsWeb) {
      return 'web';
    } else if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    } else {
      return 'unknown';
    }
  }

  /// Get App Check configuration info
  Future<Map<String, dynamic>> getDebugInfo() async {
    return {
      'initialized': _initialized,
      'platform': currentPlatform,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
