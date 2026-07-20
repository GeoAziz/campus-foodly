import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants.dart';
import '../../core/routes.dart';
import '../../data/models/campus.dart';
import '../../data/providers/campus_provider.dart';

class CampusSelectorScreen extends ConsumerWidget {
  const CampusSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campuses = ref.watch(allCampusesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Campus'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: campuses.when(
        data: (campusList) {
          if (campusList.isEmpty) {
            return const Center(
              child: Text('No campuses available'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(defaultPadding),
            itemCount: campusList.length,
            itemBuilder: (context, index) {
              final campus = campusList[index];
              return CampusCard(
                campus: campus,
                onTap: () {
                  ref
                      .read(selectedCampusIdProvider.notifier)
                      .setSelectedCampus(campus.id);
                  context.pushNamed(AppRoutes.app);
                },
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(defaultPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Error Loading Campuses',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please check your connection and try again.\n\nError: $error',
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CampusCard extends StatelessWidget {
  const CampusCard({
    super.key,
    required this.campus,
    required this.onTap,
  });

  final Campus campus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: defaultPadding),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Name and short name
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          campus.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (campus.description != null)
                          Text(
                            campus.description!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      campus.shortName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: defaultPadding),
              // Delivery info
              Row(
                children: [
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.local_shipping,
                      label: 'Delivery',
                      value: 'KES ${campus.deliveryFee.toStringAsFixed(0)}',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: defaultPadding),
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.shopping_cart,
                      label: 'Min Order',
                      value: 'KES ${campus.minOrder.toStringAsFixed(0)}',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: defaultPadding),
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.location_on,
                      label: 'Radius',
                      value: '${(campus.radiusMeters / 1000).toStringAsFixed(1)}km',
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: defaultPadding),
              // Select button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Select Campus'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 20,
          color: primaryColor,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
