import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import 'core/theme.dart';
import 'core/router.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/theme_provider.dart';
import 'data/services/firebase_service.dart';
import 'data/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? firebaseInitError;

  try {
    await FirebaseService.initialize();
  } catch (error) {
    firebaseInitError = error;
  }

  runApp(
    ProviderScope(
      child: MyApp(firebaseInitError: firebaseInitError),
    ),
  );

  if (firebaseInitError == null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(NotificationService.initialize());
    });
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key, this.firebaseInitError});

  final Object? firebaseInitError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authStateChangesProvider, (previous, next) {
      next.whenData((user) {
        if (user == null) {
          NotificationService.clearSyncedUser();
          return;
        }
        NotificationService.syncTokenForUser(user.id);
      });
    });

    if (firebaseInitError != null) {
      return MaterialApp(
        title: 'OrderEats',
        theme: buildLightThemeData(),
        darkTheme: buildDarkThemeData(),
        home: Scaffold(
          appBar: AppBar(title: const Text('Configuration Error')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Firebase initialization failed. Add platform Firebase files and valid options before running the app.\n\nError: $firebaseInitError',
                textAlign: TextAlign.center,
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
      title: 'OrderEats',
      theme: buildLightThemeData(),
      darkTheme: buildDarkThemeData(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
