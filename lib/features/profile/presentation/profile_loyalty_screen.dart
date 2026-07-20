import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants.dart';
import '../../../data/models/loyalty.dart';
import '../../../data/providers/loyalty_provider.dart';

class LoyaltyScreen extends ConsumerWidget {
  const LoyaltyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loyaltyAsync = ref.watch(userLoyaltyNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loyalty Points'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: loyaltyAsync.when(
        data: (loyalty) {
          if (loyalty == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.card_giftcard, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: defaultPadding),
                  Text('No Loyalty Account', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Start ordering to earn points!',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Points Balance Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, primaryColor.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(defaultPadding * 2),
                    child: Column(
                      children: [
                        Text(
                          'Your Points Balance',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${loyalty.pointsBalance}',
                          style:
                              Theme.of(context).textTheme.displayMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: (loyalty.pointsBalance %
                                  LoyaltyRecord.pointsForRedemption) /
                              LoyaltyRecord.pointsForRedemption,
                          backgroundColor: Colors.white30,
                          minHeight: 8,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${loyalty.pointsBalance % LoyaltyRecord.pointsForRedemption}/${LoyaltyRecord.pointsForRedemption} points to next voucher',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: defaultPadding * 2),
                // How to Earn Points
                Text(
                  'How to Earn Points',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: defaultPadding),
                _buildEarnItem(
                  context,
                  icon: Icons.shopping_bag,
                  title: 'Every Order',
                  description: '1 point per KES 10 spent',
                ),
                _buildEarnItem(
                  context,
                  icon: Icons.card_giftcard,
                  title: 'Referral',
                  description: '50 points when friend orders',
                ),
                const SizedBox(height: defaultPadding * 2),
                // Redeem Section
                Text(
                  'Redeem Points',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: defaultPadding),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(defaultPadding),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${LoyaltyRecord.pointsForRedemption} Points',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'KES ${LoyaltyRecord.voucherValue} Voucher',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: loyalty.canRedeem()
                                  ? () {
                                      // Show confirmation
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Redeem Voucher?'),
                                          content: Text(
                                            'Convert ${LoyaltyRecord.pointsForRedemption} points to KES ${LoyaltyRecord.voucherValue} voucher?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                ref
                                                    .read(
                                                      userLoyaltyNotifierProvider
                                                          .notifier,
                                                    )
                                                    .redeemPoints(
                                                      LoyaltyRecord
                                                          .pointsForRedemption,
                                                    );
                                                Navigator.pop(ctx);
                                              },
                                              child: const Text('Redeem'),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  : null,
                              child: const Text('Redeem'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: defaultPadding * 2),
                // Stats
                Text(
                  'Your Stats',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: defaultPadding),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        label: 'Total Earned',
                        value: '${loyalty.pointsEarned}',
                      ),
                    ),
                    const SizedBox(width: defaultPadding),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        label: 'Redeemed',
                        value: '${loyalty.pointsRedeemed}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildEarnItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: defaultPadding),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryColor),
          ),
          const SizedBox(width: defaultPadding),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                description,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: primaryColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
