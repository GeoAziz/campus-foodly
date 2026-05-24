import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Service for managing crash reporting and error tracking
/// Integrates with Firebase Crashlytics for production error monitoring
class CrashReportingService {
  static final CrashReportingService _instance = CrashReportingService._internal();
  static final Logger _logger = Logger();
  
  late final FirebaseCrashlytics _crashlytics;
  bool _initialized = false;

  factory CrashReportingService() {
    return _instance;
  }

  CrashReportingService._internal();

  /// Initialize crash reporting service
  Future<void> initialize() async {
    if (_initialized) return;

    _crashlytics = FirebaseCrashlytics.instance;

    // Only collect crash reports in production
    if (!kDebugMode) {
      // Pass all uncaught errors to Crashlytics
      FlutterError.onError = (FlutterErrorDetails details) {
        FirebaseCrashlytics.instance.recordFlutterError(details);
      };

      // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }

    _initialized = true;
    _logger.i('CrashReportingService initialized');
  }

  /// Record a custom error/exception
  Future<void> recordError({
    required dynamic exception,
    required StackTrace stackTrace,
    String? reason,
    bool fatal = false,
  }) async {
    _logger.e('Recording error: $exception');
    await _crashlytics.recordError(
      exception,
      stackTrace,
      reason: reason,
      fatal: fatal,
    );
  }

  /// Set custom key-value pairs for context
  void setCustomKey({required String key, required dynamic value}) {
    _crashlytics.setCustomKey(key, value);
    _logger.d('Set custom key: $key = $value');
  }

  /// Set user information for error reports
  Future<void> setUserInfo({
    required String userId,
    String? email,
    String? username,
  }) async {
    _crashlytics.setUserIdentifier(userId);
    if (email != null) {
      _crashlytics.setCustomKey('email', email);
    }
    if (username != null) {
      _crashlytics.setCustomKey('username', username);
    }
    _logger.i('User info set: $userId');
  }

  /// Clear user information (e.g., on logout)
  Future<void> clearUserInfo() async {
    _logger.i('Clearing user info');
    // Note: Firebase Crashlytics doesn't have a direct clear method
    // Instead, set empty values or use the next userId
  }

  /// Manually trigger a crash (for testing)
  void crashApp() {
    _logger.w('Triggering crash for testing');
    _crashlytics.crash();
  }

  /// Enable/disable crash collection
  Future<void> setCrashCollectionEnabled(bool enabled) async {
    await _crashlytics.setCrashCollectionEnabled(enabled);
    _logger.i('Crash collection enabled: $enabled');
  }

  /// Check if crash collection is enabled
  bool get isCrashCollectionEnabled {
    return _crashlytics.isCrashCollectionEnabled;
  }
}
