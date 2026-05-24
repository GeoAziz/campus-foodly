import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:logger/logger.dart';
import 'dart:io' show Platform;

/// Service for managing Firebase App Check
/// App Check helps protect backend resources from abuse by verifying requests from your app
class AppCheckService {
  static final AppCheckService _instance = AppCheckService._internal();
  static final Logger _logger = Logger();

  bool _initialized = false;

  factory AppCheckService() {
    return _instance;
  }

  AppCheckService._internal();

  /// Initialize Firebase App Check
  /// This should be called after Firebase initialization
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Use reCAPTCHA v3 for web, or device check for mobile
      await FirebaseAppCheck.instance.activate(
        webRecaptchaSiteKey: null, // Configure in Firebase Console
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.appAttestProvider,
      );

      _logger.i('Firebase App Check initialized successfully');
      _initialized = true;

      // Enable debug token in development
      // Uncomment the following to use App Check with an emulator
      // await FirebaseAppCheck.instance.getToken(forceRefresh: true);
    } catch (e) {
      _logger.e('Failed to initialize Firebase App Check: $e');
      // App Check is optional - the app can still function without it
      // but it's highly recommended for production
    }
  }

  /// Get App Check token
  /// Returns null if App Check is not available or has not been initialized
  Future<String?> getToken({bool forceRefresh = false}) async {
    try {
      final token = await FirebaseAppCheck.instance.getToken(
        forceRefresh: forceRefresh,
      );
      _logger.d('App Check token obtained');
      return token?.token;
    } catch (e) {
      _logger.w('Failed to get App Check token: $e');
      return null;
    }
  }

  /// Get limited use token for sensitive operations
  /// Limited-use tokens have a restricted lifetime and can only be used once
  Future<String?> getLimitedUseToken() async {
    try {
      final token = await FirebaseAppCheck.instance.getLimitedUseToken();
      _logger.d('Limited use token obtained');
      return token?.token;
    } catch (e) {
      _logger.w('Failed to get limited use token: $e');
      return null;
    }
  }

  /// Check if App Check is initialized and available
  bool get isInitialized => _initialized;

  /// Get current platform
  String get currentPlatform {
    if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    } else if (Platform.isWeb) {
      return 'web';
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
