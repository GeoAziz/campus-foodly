import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../components/buttons/primary_button.dart';
import '../../components/welcome_text.dart';
import '../../core/routes.dart';
import '../../constants.dart';
import '../../data/providers/ui_state_provider.dart';

class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Sign In'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const WelcomeText(
                title: 'Get started with Campus Foodly',
                text:
                    'Enter your phone number to continue with secure sign in.',
              ),
              const SizedBox(height: defaultPadding),
              Form(
                key: _formKey,
                child: TextFormField(
                  validator: phoneNumberValidator.call,
                  autofocus: true,
                  onChanged: (value) => ref
                      .read(phoneLoginControllerProvider.notifier)
                      .updatePhoneNumber(value),
                  onSaved: (value) => ref
                      .read(phoneLoginControllerProvider.notifier)
                      .updatePhoneNumber(value ?? ''),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(color: titleColor),
                  cursorColor: primaryColor,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Phone Number',
                    contentPadding: kTextFieldPadding,
                  ),
                ),
              ),
              const Spacer(),
              PrimaryButton(
                text: 'Send code',
                press: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final sent = await ref
                        .read(phoneLoginControllerProvider.notifier)
                        .sendVerificationCode();
                    if (!context.mounted || !sent) {
                      return;
                    }
                    context.pushNamed(AppRoutes.numberVerify);
                  }
                },
              ),
              const SizedBox(height: defaultPadding),
            ],
          ),
        ),
      ),
    );
  }
}
