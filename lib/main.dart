import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import 'core/theme.dart';
import 'core/router.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/theme_provider.dart';
import 'data/services/firebase_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/crash_reporting_service.dart';
import 'data/services/app_check_service.dart';
import 'data/services/connectivity_service.dart';
import 'data/services/idempotency_service.dart';
import 'data/services/logger_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging first
  final logger = LoggerService();
  logger.i('=== Campus Foodly App Starting ===');

  Object? firebaseInitError;
  List<String> initializationWarnings = [];

  try {
    // Initialize Firebase Core
    logger.i('Initializing Firebase...');
    await FirebaseService.initialize();
    logger.i('Firebase initialized successfully');

    // Initialize Firebase App Check for security
    logger.i('Initializing Firebase App Check...');
    await AppCheckService().initialize();

    // Initialize Crash Reporting
    logger.i('Initializing Crash Reporting...');
    await CrashReportingService().initialize();

    // Initialize Connectivity Service for offline support
    logger.i('Initializing Connectivity Service...');
    await ConnectivityService().initialize();

    // Initialize Idempotency Service for duplicate prevention
    logger.i('Initializing Idempotency Service...');
    await IdempotencyService().initialize();

    logger.i('All services initialized successfully');
  } catch (error) {
    firebaseInitError = error;
    logger.e('Initialization error: $error');
  }

  runApp(
    ProviderScope(
      child: MyApp(
        firebaseInitError: firebaseInitError,
        initializationWarnings: initializationWarnings,
      ),
    ),
  );

  if (firebaseInitError == null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(NotificationService.initialize());
      logger.i('Notification Service initialized');
    });
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({
    super.key,
    this.firebaseInitError,
    this.initializationWarnings = const [],
  });

  final Object? firebaseInitError;
  final List<String> initializationWarnings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logger = LoggerService();

    ref.listen(authStateChangesProvider, (previous, next) {
      next.whenData((user) {
        if (user == null) {
          logger.i('User logged out');
          NotificationService.clearSyncedUser();
          CrashReportingService().clearUserInfo();
          return;
        }
        logger.i('User logged in: ${user.id}');
        NotificationService.syncTokenForUser(user.id);
        // Set user info for crash reporting
        CrashReportingService().setUserInfo(userId: user.id);
      });
    });

    if (firebaseInitError != null) {
      return MaterialApp(
        title: 'Campus Foodly',
        theme: buildLightThemeData(),
        darkTheme: buildDarkThemeData(),
        home: Scaffold(
          appBar: AppBar(title: const Text('Configuration Error')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Firebase Initialization Failed',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add platform Firebase files and valid options before running the app.\n\nError: $firebaseInitError',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      logger.i('Retry button pressed');
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final themeModeAsync = ref.watch(themeModeProvider);
    final themeMode = themeModeAsync.valueOrNull ?? ThemeMode.system;
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Campus Foodly',
      theme: buildLightThemeData(),
      darkTheme: buildDarkThemeData(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
