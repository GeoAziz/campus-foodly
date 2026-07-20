import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/skeleton/skeleton_line.dart';
import '../../../components/skeleton/skeleton_rounded_container.dart';
import '../../../data/providers/auth_provider.dart';
import '../providers/social_accounts_controller.dart';

class ProfileSocialScreen extends ConsumerWidget {
  const ProfileSocialScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.valueOrNull;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Social Accounts')),
        body: const Center(child: Text('User not found')),
      );
    }

    final socialState = ref.watch(socialAccountsControllerProvider(user.id));
    final controller =
        ref.read(socialAccountsControllerProvider(user.id).notifier);

    const providers = ['Google', 'Facebook', 'Apple'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Accounts'),
        elevation: 0,
      ),
      body: socialState.isLoading && socialState.accounts.isEmpty
          ? SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: List.generate(
                    3,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  SkeletonRoundedContainer(
                                    height: 32,
                                    width: 32,
                                    radius: 8,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SkeletonLine(height: 16),
                                        const SizedBox(height: 8),
                                        SkeletonLine(
                                          height: 12,
                                          width: 150,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  if (socialState.error != null)
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .error
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Theme.of(context).colorScheme.error),
                      ),
                      child: Text(
                        socialState.error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    )
                  else if (socialState.success)
                    Container(
                      margin: const EdgeInsets.all(16),
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
                        'Social account updated',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Link your social accounts for easier sign-in',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        for (final provider in providers)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _SocialProviderCard(
                              provider: provider,
                              isLinked: socialState.isProviderLinked(
                                provider.toLowerCase(),
                              ),
                              linkedAccount: socialState.getLinkedAccount(
                                provider.toLowerCase(),
                              ),
                              onLink: () {
                                _showLinkDialog(context, provider, controller);
                              },
                              onUnlink: () {
                                _showUnlinkDialog(
                                  context,
                                  provider,
                                  controller,
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showLinkDialog(
    BuildContext context,
    String provider,
    SocialAccountsController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Link $provider Account?'),
        content: Text(
          'You will be redirected to $provider to link your account',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$provider linking is not yet implemented'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Link'),
          ),
        ],
      ),
    );
  }

  void _showUnlinkDialog(
    BuildContext context,
    String provider,
    SocialAccountsController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unlink $provider?'),
        content: Text(
          'Your $provider account will be unlinked from your Foodly account',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.unlinkAccount(provider.toLowerCase());
              Navigator.pop(context);
            },
            child: Text(
              'Unlink',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialProviderCard extends StatelessWidget {
  final String provider;
  final bool isLinked;
  final dynamic linkedAccount;
  final VoidCallback onLink;
  final VoidCallback onUnlink;

  const _SocialProviderCard({
    required this.provider,
    required this.isLinked,
    required this.linkedAccount,
    required this.onLink,
    required this.onUnlink,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(
          _getProviderIcon(provider),
          size: 32,
        ),
        title: Text(provider),
        subtitle: isLinked
            ? Text(
                'Linked as ${linkedAccount?.email ?? 'Unknown'}',
                overflow: TextOverflow.ellipsis,
              )
            : const Text('Not linked'),
        trailing: FilledButton(
          onPressed: isLinked ? onUnlink : onLink,
          style: FilledButton.styleFrom(
            backgroundColor: isLinked
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
          ),
          child: Text(isLinked ? 'Unlink' : 'Link'),
        ),
      ),
    );
  }

  IconData _getProviderIcon(String provider) {
    switch (provider.toLowerCase()) {
      case 'google':
        return Icons.g_mobiledata;
      case 'facebook':
        return Icons.facebook;
      case 'apple':
        return Icons.apple;
      default:
        return Icons.account_circle;
    }
  }
}
