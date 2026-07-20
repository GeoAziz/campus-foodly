import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants.dart';
import '../../../data/providers/campus_provider.dart';
import '../../../core/utils/geofence_helper.dart';
import '../../../data/models/address.dart';

class AddressPickerScreen extends ConsumerWidget {
  const AddressPickerScreen({
    super.key,
    required this.onAddressSelected,
  });

  final Function(Address) onAddressSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCampusAsync = ref.watch(selectedCampusProvider);

    return selectedCampusAsync.when(
      data: (campus) {
        if (campus == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Select Delivery Address')),
            body: const Center(
              child: Text('No campus selected. Please select a campus first.'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Select Delivery Address'),
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Campus info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery Campus',
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            campus.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Delivery Radius: ${(campus.radiusMeters / 1000).toStringAsFixed(1)}km',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: defaultPadding * 2),
                  // Address input
                  Text(
                    'Enter Delivery Address',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: defaultPadding),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'E.g., Hostel Block C, Room 204',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.location_on),
                    ),
                    maxLines: 3,
                    minLines: 2,
                  ),
                  const SizedBox(height: defaultPadding * 2),
                  // Info box
                  Container(
                    padding: const EdgeInsets.all(defaultPadding),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info, color: primaryColor),
                        const SizedBox(width: defaultPadding),
                        Expanded(
                          child: Text(
                            'Ensure your address is within ${campus.name} campus geofence.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: defaultPadding * 2),
                  // Action buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // For now, just use the entered address
                        // In production, integrate with Google Maps for address picking
                        final address = Address(
                          id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
                          label: 'Delivery Address',
                          address: 'Hostel Block C, Room 204',
                          latitude: campus.latitude,
                          longitude: campus.longitude,
                          isDefault: false,
                        );
                        onAddressSelected(address);
                        context.pop();
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Confirm Address'),
                    ),
                  ),
                  const SizedBox(height: defaultPadding),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Select Delivery Address')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Select Delivery Address')),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}

// Placeholder Address model (if not exists in models/)
class Address {
  const Address({
    required this.id,
    required this.label,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
  });

  final String id;
  final String label;
  final String address;
  final double latitude;
  final double longitude;
  final bool isDefault;
}
