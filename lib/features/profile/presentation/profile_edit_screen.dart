import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers/auth_provider.dart';
import '../providers/profile_edit_controller.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late TextEditingController _displayNameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _phoneController = TextEditingController();
    _bioController = TextEditingController();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _initializeControllers(ProfileEditState editState) {
    _displayNameController.text = editState.displayName ?? '';
    _phoneController.text = editState.phone ?? '';
    _bioController.text = editState.bio ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.valueOrNull;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const Center(child: Text('User not found')),
      );
    }

    ref.listen<ProfileEditState>(
      profileEditControllerProvider(user.id),
      (previous, next) {
        final switchedToViewMode =
            previous?.mode != next.mode && next.mode == ProfileEditMode.view;
        if (switchedToViewMode) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _initializeControllers(next);
          });
        }
      },
    );

    final editState = ref.watch(profileEditControllerProvider(user.id));

    // Initialize controllers when profile data loads
    if (editState.profileData != null && _displayNameController.text.isEmpty) {
      _initializeControllers(editState);
    }

    return PopScope(
      canPop: !editState.hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Show warning dialog if there are unsaved changes
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Unsaved Changes'),
            content: const Text('You have unsaved changes. Do you want to discard them?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Keep Editing'),
              ),
              TextButton(
                onPressed: () {
                  // Cancel edit mode and discard changes
                  ref
                      .read(profileEditControllerProvider(user.id).notifier)
                      .cancelEdit();
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Discard'),
              ),
            ],
          ),
        );
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        elevation: 0,
      ),
      body: editState.isLoading && editState.profileData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (editState.error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .error
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Theme.of(context).colorScheme.error),
                        ),
                        child: Text(
                          editState.error!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error),
                        ),
                      )
                    else if (editState.success)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Theme.of(context).colorScheme.primary),
                        ),
                        child: Text(
                          'Profile updated successfully',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                    if (editState.error != null || editState.success)
                      const SizedBox(height: 16),
                    // Email (read-only)
                    Text(
                      'Email',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: editState.profileData?.email ?? '',
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey.withValues(alpha: 0.1),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Display Name
                    Text(
                      'Full Name',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _displayNameController,
                      readOnly: editState.mode == ProfileEditMode.view,
                      onChanged: (value) {
                        ref
                            .read(
                                profileEditControllerProvider(user.id).notifier)
                            .updateDisplayName(value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Full Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Phone
                    Text(
                      'Phone Number',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      readOnly: editState.mode == ProfileEditMode.view,
                      onChanged: (value) {
                        ref
                            .read(
                                profileEditControllerProvider(user.id).notifier)
                            .updatePhone(value);
                      },
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Phone Number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Bio
                    Text(
                      'Bio',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _bioController,
                      readOnly: editState.mode == ProfileEditMode.view,
                      onChanged: (value) {
                        ref
                            .read(
                                profileEditControllerProvider(user.id).notifier)
                            .updateBio(value);
                      },
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Tell us about yourself',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Action Buttons
                    if (editState.mode == ProfileEditMode.view)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            ref
                                .read(profileEditControllerProvider(user.id)
                                    .notifier)
                                .enterEditMode();
                          },
                          child: const Text('Edit Profile'),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                ref
                                    .read(profileEditControllerProvider(user.id)
                                        .notifier)
                                    .cancelEdit();
                              },
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: editState.isLoading
                                  ? null
                                  : () {
                                      ref
                                          .read(profileEditControllerProvider(
                                                  user.id)
                                              .notifier)
                                          .saveProfile();
                                    },
                              child: editState.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Text('Save Changes'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}
