import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../constants.dart';
import '../providers/order_tracking_provider.dart';

class OrderTrackingScreen extends ConsumerWidget {
  const OrderTrackingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingAsync = ref.watch(orderTrackingStreamProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Order Tracking')),
      body: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: trackingAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text(
              'Tracking unavailable: ${error.toString()}',
              textAlign: TextAlign.center,
            ),
          ),
          data: (tracking) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order: ${tracking.orderId}'),
              const SizedBox(height: defaultPadding / 2),
              Text('Status: ${tracking.status}'),
              const SizedBox(height: defaultPadding / 2),
              Text(
                'Last update: ${tracking.updatedAt.toLocal()}',
              ),
              const SizedBox(height: defaultPadding),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        tracking.latitude == 0 ? -1.2921 : tracking.latitude,
                        tracking.longitude == 0 ? 36.8219 : tracking.longitude,
                      ),
                      zoom: 13,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('order'),
                        position: LatLng(
                          tracking.latitude == 0 ? -1.2921 : tracking.latitude,
                          tracking.longitude == 0
                              ? 36.8219
                              : tracking.longitude,
                        ),
                        infoWindow: InfoWindow(
                          title: 'Order $orderId',
                          snippet: tracking.status,
                        ),
                      ),
                    },
                    polylines: {
                      Polyline(
                        polylineId: const PolylineId('route'),
                        points: [
                          const LatLng(-1.2921, 36.8219),
                          LatLng(
                            tracking.latitude == 0
                                ? -1.2921
                                : tracking.latitude,
                            tracking.longitude == 0
                                ? 36.8219
                                : tracking.longitude,
                          ),
                        ],
                        color: primaryColor,
                        width: 4,
                      ),
                    },
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
