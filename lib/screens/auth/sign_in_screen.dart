import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../components/welcome_text.dart';
import '../../core/routes.dart';
import '../../constants.dart';
import 'components/sign_in_form.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const SizedBox(),
        title: const Text("Sign In"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const WelcomeText(
                title: "Welcome to",
                text:
                    "Enter your Phone number or Email \naddress for sign in. Enjoy your food :)",
              ),
              const SignInForm(),
              const SizedBox(height: defaultPadding),
              kOrText,
              const SizedBox(height: defaultPadding * 1.5),

              Center(
                child: TextButton(
                  onPressed: () => context.pushNamed(AppRoutes.phoneLogin),
                  child: const Text('Use phone number instead'),
                ),
              ),
              const SizedBox(height: defaultPadding / 2),

              Center(
                child: Text.rich(
                  TextSpan(
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(fontWeight: FontWeight.w600),
                    text: "Don't have an account? ",
                    children: <TextSpan>[
                      TextSpan(
                        text: "Create new account.",
                        style: const TextStyle(color: primaryColor),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => context.pushNamed(AppRoutes.signUp),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: defaultPadding),
            ],
          ),
        ),
      ),
    );
  }
}
