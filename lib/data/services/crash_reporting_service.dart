import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Service for managing crash reporting and error tracking
/// Integrates with Firebase Crashlytics for production error monitoring
class CrashReportingService {
  static final CrashReportingService _instance =
      CrashReportingService._internal();
  static final Logger _logger = Logger();

  late final FirebaseCrashlytics _crashlytics;
  bool _initialized = false;
  final List<String> _breadcrumbs = [];
  static const int _maxBreadcrumbs = 50;

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

  /// Add a breadcrumb for debugging
  void addBreadcrumb({
    required String message,
    String? category,
    Map<String, dynamic>? data,
  }) {
    try {
      final timestamp = DateTime.now().toIso8601String();
      final breadcrumb = '[$timestamp] $category: $message';

      _breadcrumbs.add(breadcrumb);

      // Keep only recent breadcrumbs
      if (_breadcrumbs.length > _maxBreadcrumbs) {
        _breadcrumbs.removeAt(0);
      }

      // Set as custom key for crash reports
      _crashlytics.setCustomKey('breadcrumbs_count', _breadcrumbs.length);

      if (data != null) {
        data.forEach((key, value) {
          _crashlytics.setCustomKey('breadcrumb_$key', value);
        });
      }

      _logger.d('Breadcrumb added: $breadcrumb');
    } catch (e) {
      _logger.e('Error adding breadcrumb: $e');
    }
  }

  /// Record a custom error/exception
  Future<void> recordError({
    required dynamic exception,
    required StackTrace stackTrace,
    String? reason,
    bool fatal = false,
  }) async {
    try {
      _logger.e('Recording error: $exception');

      // Add breadcrumbs to context
      for (int i = 0; i < _breadcrumbs.length; i++) {
        _crashlytics.setCustomKey('breadcrumb_$i', _breadcrumbs[i]);
      }

      await _crashlytics.recordError(
        exception,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );
    } catch (e) {
      _logger.e('Error recording crash: $e');
    }
  }

  /// Set custom key-value pairs for context
  void setCustomKey({required String key, required dynamic value}) {
    try {
      _crashlytics.setCustomKey(key, value);
      _logger.d('Set custom key: $key = $value');
    } catch (e) {
      _logger.e('Error setting custom key: $e');
    }
  }

  /// Set user information for error reports
  Future<void> setUserInfo({
    required String userId,
    String? email,
    String? username,
  }) async {
    try {
      _crashlytics.setUserIdentifier(userId);
      if (email != null) {
        _crashlytics.setCustomKey('email', email);
      }
      if (username != null) {
        _crashlytics.setCustomKey('username', username);
      }
      _logger.i('User info set: $userId');
    } catch (e) {
      _logger.e('Error setting user info: $e');
    }
  }

  /// Clear user information (e.g., on logout)
  Future<void> clearUserInfo() async {
    try {
      // Clear breadcrumbs on logout
      _breadcrumbs.clear();
      _crashlytics.setCustomKey('breadcrumbs_count', 0);

      // Set empty user identifier
      _crashlytics.setUserIdentifier('');

      _logger.i('User info and breadcrumbs cleared');
    } catch (e) {
      _logger.e('Error clearing user info: $e');
    }
  }

  /// Get breadcrumbs for debugging
  List<String> getBreadcrumbs() => List.from(_breadcrumbs);

  /// Clear all breadcrumbs
  void clearBreadcrumbs() {
    _breadcrumbs.clear();
    _logger.d('Breadcrumbs cleared');
  }

  /// Manually trigger a crash (for testing)
  void crashApp() {
    _logger.w('Triggering crash for testing');
    _crashlytics.crash();
  }
}
