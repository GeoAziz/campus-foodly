import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../components/welcome_text.dart';
import '../../core/routes.dart';
import '../../constants.dart';
import '../../data/providers/ui_state_provider.dart';
import 'components/otp_form.dart';

class NumberVerifyScreen extends ConsumerWidget {
  const NumberVerifyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phoneState = ref.watch(phoneLoginControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Verification'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WelcomeText(
                title: "Verify phone number",
                text: phoneState.phoneNumber.isEmpty
                    ? "Enter the code sent to your phone number"
                    : "Enter the code sent to you at ${phoneState.phoneNumber}",
              ),

              // OTP form
              const OtpForm(),
              const SizedBox(height: defaultPadding),
              Center(
                child: Text.rich(
                  TextSpan(
                    text: "Didn’t receive code? ",
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(fontWeight: FontWeight.w500),
                    children: <TextSpan>[
                      TextSpan(
                        text: "Resend Again.",
                        style: const TextStyle(color: primaryColor),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            await ref
                                .read(phoneLoginControllerProvider.notifier)
                                .sendVerificationCode();
                          },
                      ),
                    ],
                  ),
                ),
              ),
              if (phoneState.status == PhoneAuthStatus.failed &&
                  phoneState.errorMessage != null) ...[
                const SizedBox(height: defaultPadding),
                Text(
                  phoneState.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: defaultPadding),
              Center(
                child: TextButton(
                  onPressed: () {
                    ref.read(phoneLoginControllerProvider.notifier).reset();
                    context.goNamed(AppRoutes.phoneLogin);
                  },
                  child: const Text('Use a different number'),
                ),
              ),
              const SizedBox(height: defaultPadding),
              const Center(
                child: Text(
                  "By Signing up you agree to our Terms \nConditions & Privacy Policy.",
                  textAlign: TextAlign.center,
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
