import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../components/welcome_text.dart';
import '../../core/routes.dart';
import '../../constants.dart';
import '../../data/providers/auth_provider.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Forgot Password"),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WelcomeText(
                title: "Forgot password",
                text:
                    "Enter your email address and we will \nsend you a reset instructions."),
            SizedBox(height: defaultPadding),
            ForgotPassForm(),
          ],
        ),
      ),
    );
  }
}

class ForgotPassForm extends ConsumerStatefulWidget {
  const ForgotPassForm({super.key});

  @override
  ConsumerState<ForgotPassForm> createState() => _ForgotPassFormState();
}

class _ForgotPassFormState extends ConsumerState<ForgotPassForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email Field
          TextFormField(
            controller: _emailController,
            validator: emailValidator.call,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: "Email Address"),
          ),
          const SizedBox(height: defaultPadding),

          // Reset password Button
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final email = _emailController.text.trim();
                final sent = await ref
                    .read(authControllerProvider.notifier)
                    .sendPasswordResetEmail(email: email);
                if (!context.mounted || !sent) {
                  return;
                }
                context.pushNamed(
                  AppRoutes.resetEmailSent,
                  queryParameters: {'email': email},
                );
              }
            },
            child: const Text("Reset password"),
          ),
        ],
      ),
    );
  }
}
