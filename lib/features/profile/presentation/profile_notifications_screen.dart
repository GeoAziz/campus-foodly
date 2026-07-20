import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/skeleton/skeleton_line.dart';
import '../../../components/skeleton/skeleton_rounded_container.dart';
import '../../../data/providers/auth_provider.dart';
import '../providers/notification_preferences_controller.dart';

class ProfileNotificationsScreen extends ConsumerWidget {
  const ProfileNotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.valueOrNull;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notification Settings')),
        body: const Center(child: Text('User not found')),
      );
    }

    final notifyState =
        ref.watch(notificationPreferencesControllerProvider(user.id));
    final controller =
        ref.read(notificationPreferencesControllerProvider(user.id).notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        elevation: 0,
      ),
      body: notifyState.isLoading && notifyState.preferences == null
          ? SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: List.generate(
                    5,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SkeletonLine(
                                  height: 16,
                                  width: 150,
                                ),
                                const SizedBox(height: 8),
                                SkeletonLine(
                                  height: 12,
                                  width: 200,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          SkeletonRoundedContainer(
                            height: 24,
                            width: 50,
                            radius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  if (notifyState.error != null)
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
                        notifyState.error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    )
                  else if (notifyState.success)
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
                        'Notification preferences updated',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  if (notifyState.preferences != null)
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Choose what notifications you want to receive',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        _NotificationSwitch(
                          title: 'Push Notifications',
                          subtitle: 'Receive push notifications on your device',
                          value: notifyState.preferences!.pushNotifications,
                          onChanged: (value) =>
                              controller.togglePushNotifications(),
                        ),
                        _NotificationSwitch(
                          title: 'Order Updates',
                          subtitle:
                              'Get notified when your order status changes',
                          value: notifyState.preferences!.orderUpdates,
                          onChanged: (value) => controller.toggleOrderUpdates(),
                        ),
                        _NotificationSwitch(
                          title: 'Promotions',
                          subtitle: 'Receive special offers and discounts',
                          value: notifyState.preferences!.promotions,
                          onChanged: (value) => controller.togglePromotions(),
                        ),
                        _NotificationSwitch(
                          title: 'New Restaurants',
                          subtitle:
                              'Be the first to know about new restaurants',
                          value: notifyState.preferences!.newRestaurants,
                          onChanged: (value) =>
                              controller.toggleNewRestaurants(),
                        ),
                        _NotificationSwitch(
                          title: 'Restaurant Offers',
                          subtitle:
                              'Receive special offers from your favorite restaurants',
                          value: notifyState.preferences!.restaurantOffers,
                          onChanged: (value) =>
                              controller.toggleRestaurantOffers(),
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
}

class _NotificationSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final Function(bool) onChanged;

  const _NotificationSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
