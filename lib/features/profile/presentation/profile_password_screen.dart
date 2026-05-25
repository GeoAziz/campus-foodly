import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/password_change_controller.dart';

class ProfilePasswordScreen extends ConsumerWidget {
  const ProfilePasswordScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passwordState = ref.watch(passwordChangeControllerProvider);
    final passwordController =
        ref.read(passwordChangeControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'For your security, please enter your current password and then choose a new password.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),
              // Error Message
              if (passwordState.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .error
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Theme.of(context).colorScheme.error),
                  ),
                  child: Text(
                    passwordState.error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                )
              else if (passwordState.success)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  child: Text(
                    'Password changed successfully',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              if (passwordState.error != null || passwordState.success)
                const SizedBox(height: 16),
              // Current Password Field
              Text(
                'Current Password',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextFormField(
                obscureText: !passwordState.showCurrentPassword,
                onChanged: passwordController.updateCurrentPassword,
                decoration: InputDecoration(
                  hintText: 'Enter your current password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      passwordState.showCurrentPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed:
                        passwordController.toggleCurrentPasswordVisibility,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // New Password Field
              Text(
                'New Password',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextFormField(
                obscureText: !passwordState.showNewPassword,
                onChanged: passwordController.updateNewPassword,
                decoration: InputDecoration(
                  hintText: 'Enter your new password (min 6 characters)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      passwordState.showNewPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: passwordController.toggleNewPasswordVisibility,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Confirm Password Field
              Text(
                'Confirm New Password',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextFormField(
                obscureText: !passwordState.showConfirmPassword,
                onChanged: passwordController.updateConfirmPassword,
                decoration: InputDecoration(
                  hintText: 'Confirm your new password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      passwordState.showConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed:
                        passwordController.toggleConfirmPasswordVisibility,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: passwordState.isLoading
                      ? null
                      : () {
                          passwordController.changePassword();
                        },
                  child: passwordState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Change Password'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    passwordController.reset();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
