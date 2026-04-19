import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants.dart';

import '../../components/welcome_text.dart';
import '../../data/providers/auth_provider.dart';
import '../../core/routes.dart';

class ResetEmailSentScreen extends ConsumerWidget {
  const ResetEmailSentScreen({super.key, this.email = ''});

  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Forgot Password"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const WelcomeText(
                title: 'Reset email sent',
                text:
                    'We have sent password reset instructions to\nyour email address.'),
            if (email.isNotEmpty) ...[
              const SizedBox(height: defaultPadding / 2),
              Text(
                email,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: defaultPadding),
            ElevatedButton(
              onPressed: email.isEmpty
                  ? null
                  : () async {
                      await ref
                          .read(authControllerProvider.notifier)
                          .sendPasswordResetEmail(email: email);
                    },
              child: const Text('Send again'),
            ),
            TextButton(
              onPressed: () => context.goNamed(AppRoutes.signIn),
              child: const Text('Back to sign in'),
            ),
          ],
        ),
      ),
    );
  }
}
