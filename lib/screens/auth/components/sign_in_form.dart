import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes.dart';
import '../../../constants.dart';
import '../../../data/providers/auth_provider.dart';

class SignInForm extends ConsumerStatefulWidget {
  const SignInForm({super.key});

  @override
  ConsumerState<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<SignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscureText = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            validator: emailValidator.call,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: "Email Address"),
            enabled: !isLoading,
          ),
          const SizedBox(height: defaultPadding),

          // Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscureText,
            validator: passwordValidator.call,
            decoration: InputDecoration(
              hintText: "Password",
              suffixIcon: GestureDetector(
                onTap: isLoading
                    ? null
                    : () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                child: _obscureText
                    ? const Icon(Icons.visibility_off, color: bodyTextColor)
                    : const Icon(Icons.visibility, color: bodyTextColor),
              ),
            ),
            enabled: !isLoading,
          ),
          const SizedBox(height: defaultPadding),

          // Forget Password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: isLoading
                  ? null
                  : () => context.pushNamed(AppRoutes.forgotPassword),
              child: const Text("Forgot Password?"),
            ),
          ),
          const SizedBox(height: defaultPadding),

          // Sign In Button with Loading State
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) {
                        return;
                      }

                      final success = await ref
                          .read(authControllerProvider.notifier)
                          .signIn(
                            email: _emailController.text.trim(),
                            password: _passwordController.text,
                          );

                      if (!context.mounted) {
                        return;
                      }

                      if (success) {
                        context.goNamed(AppRoutes.findRestaurants);
                        return;
                      }

                      final authState = ref.read(authControllerProvider);
                      final error = authState.error;
                      if (error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(authErrorMessage(error))),
                        );
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text("Sign in"),
            ),
          ),
        ],
      ),
    );
  }
}
