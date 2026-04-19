import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants.dart';
import '../../core/routes.dart';
import '../../data/providers/auth_provider.dart';

class AuthErrorScreen extends ConsumerWidget {
  const AuthErrorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final error = authState.error;

    return Scaffold(
      appBar: AppBar(title: const Text('Authentication Error')),
      body: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              error == null
                  ? 'Unknown authentication error.'
                  : authErrorMessage(error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: defaultPadding),
            ElevatedButton(
              onPressed: () => context.goNamed(AppRoutes.signIn),
              child: const Text('Back to Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}
