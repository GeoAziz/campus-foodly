import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../components/buttons/primary_button.dart';
import '../../../constants.dart';
import '../../../core/routes.dart';
import '../models/order_tracking_update.dart';
import '../providers/order_tracking_provider.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  const OrderTrackingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  bool _didRouteToDelivered = false;

  void _openDeliveredSummary() {
    if (_didRouteToDelivered) {
      return;
    }

    _didRouteToDelivered = true;
    context.pushReplacementNamed(
      AppRoutes.orderDelivered,
      pathParameters: {'orderId': widget.orderId},
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(orderTrackingStreamProvider(widget.orderId), (previous, next) {
      final previousStage = previous?.valueOrNull?.stage;
      final currentStage = next.valueOrNull?.stage;

      if (currentStage == OrderTrackingStage.delivered &&
          previousStage != OrderTrackingStage.delivered &&
          !_didRouteToDelivered) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          _openDeliveredSummary();
        });
      }
    });

    final trackingAsync =
        ref.watch(orderTrackingStreamProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Tracking'),
        actions: [
          IconButton(
            tooltip: 'Refresh tracking',
            onPressed: () =>
                ref.invalidate(orderTrackingStreamProvider(widget.orderId)),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: trackingAsync.when(
          loading: () => const _TrackingLoadingState(),
          error: (error, stackTrace) => _TrackingErrorState(
            message: _friendlyErrorMessage(error.toString()),
            onRetry: () =>
                ref.invalidate(orderTrackingStreamProvider(widget.orderId)),
          ),
          data: (tracking) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(orderTrackingStreamProvider(widget.orderId));
              await Future<void>.delayed(const Duration(milliseconds: 200));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TrackingHeaderCard(tracking: tracking),
                  const SizedBox(height: defaultPadding),
                  const _SectionHeading(
                    title: 'Delivery progress',
                    subtitle:
                        'A simple view of where your order stands right now.',
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  _StatusTimeline(tracking: tracking),
                  const SizedBox(height: defaultPadding),
                  const _SectionHeading(
                    title: 'Order details',
                    subtitle: 'Helpful context while the order is moving.',
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  _OrderDetailCard(tracking: tracking),
                  const SizedBox(height: defaultPadding),
                  const _SectionHeading(
                    title: 'Live map',
                    subtitle:
                        'The route updates automatically when location data is available.',
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  _TrackingMapCard(tracking: tracking),
                  const SizedBox(height: defaultPadding),
                  PrimaryButton(
                    text: tracking.stage == OrderTrackingStage.delivered
                        ? 'View delivery summary'
                        : 'Preview delivery summary',
                    press: _openDeliveredSummary,
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  Text(
                    tracking.stage == OrderTrackingStage.delivered
                        ? 'Order delivered. You can continue to the completion screen.'
                        : 'Summary screen is ready. Final details appear after delivery.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: bodyTextColor,
                        ),
                  ),
                  const SizedBox(height: defaultPadding),
                  const _SectionHeading(
                    title: 'Need help?',
                    subtitle:
                        'Keep support actions close if something looks off.',
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Support contact is not configured yet.'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.support_agent_rounded),
                          label: const Text('Contact support'),
                        ),
                      ),
                      const SizedBox(width: defaultPadding / 2),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Order ID copied: ${tracking.orderId}'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded),
                          label: const Text('Copy order ID'),
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
    );
  }
}

const LatLng _fallbackCenter = LatLng(-1.2921, 36.8219);

String _friendlyErrorMessage(String rawMessage) {
  if (rawMessage.toLowerCase().contains('firebase')) {
    return 'Tracking is unavailable because the backend is not ready yet. Try again in a moment.';
  }
  return 'We could not load live tracking right now. Check your connection and retry.';
}

LatLng _trackingLocation(OrderTrackingUpdate tracking) {
  if (!tracking.hasLocation) {
    return _fallbackCenter;
  }

  return LatLng(tracking.latitude, tracking.longitude);
}

Color _stageColor(OrderTrackingStage stage) {
  switch (stage) {
    case OrderTrackingStage.pending:
      return const Color(0xFF8E6D0D);
    case OrderTrackingStage.preparing:
      return primaryColor;
    case OrderTrackingStage.outForDelivery:
      return const Color(0xFF2F80ED);
    case OrderTrackingStage.delivered:
      return const Color(0xFF1E8E3E);
    case OrderTrackingStage.unknown:
      return bodyTextColor;
  }
}

class _TrackingHeaderCard extends StatelessWidget {
  const _TrackingHeaderCard({required this.tracking});

  final OrderTrackingUpdate tracking;

  @override
  Widget build(BuildContext context) {
    final stageColor = _stageColor(tracking.stage);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1F2937), Color(0xFF111827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: stageColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _iconForStage(tracking.stage),
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: defaultPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tracking.statusLabel,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Order #${tracking.orderId}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                    ),
                  ],
                ),
              ),
              _StatusPill(label: tracking.statusLabel, color: stageColor),
            ],
          ),
          const SizedBox(height: defaultPadding),
          Text(
            tracking.statusDescription,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  height: 1.45,
                ),
          ),
          const SizedBox(height: defaultPadding),
          Row(
            children: [
              Expanded(
                child: _MiniInfoTile(
                  icon: Icons.schedule_rounded,
                  label: 'Last update',
                  value: _formatDateTime(tracking.updatedAt),
                ),
              ),
              const SizedBox(width: defaultPadding / 2),
              Expanded(
                child: _MiniInfoTile(
                  icon: tracking.hasLocation
                      ? Icons.location_on_rounded
                      : Icons.place_outlined,
                  label: 'Location',
                  value:
                      tracking.hasLocation ? 'Live position' : 'Fallback area',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.tracking});

  final OrderTrackingUpdate tracking;

  @override
  Widget build(BuildContext context) {
    final steps = [
      (
        title: 'Order received',
        stage: OrderTrackingStage.pending,
        subtitle: 'Your order is in the queue.',
      ),
      (
        title: 'Preparing',
        stage: OrderTrackingStage.preparing,
        subtitle: 'The kitchen is cooking now.',
      ),
      (
        title: 'On the way',
        stage: OrderTrackingStage.outForDelivery,
        subtitle: 'A courier is heading to you.',
      ),
      (
        title: 'Delivered',
        stage: OrderTrackingStage.delivered,
        subtitle: 'Your order arrived safely.',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF2F2F2)),
      ),
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        children: [
          for (var index = 0; index < steps.length; index++)
            _TimelineRow(
              title: steps[index].title,
              subtitle: steps[index].subtitle,
              isLast: index == steps.length - 1,
              isComplete: _isStepComplete(tracking.stage, steps[index].stage),
              isCurrent: tracking.stage == steps[index].stage,
              isUnknown: tracking.stage == OrderTrackingStage.unknown,
            ),
        ],
      ),
    );
  }
}

bool _isStepComplete(OrderTrackingStage current, OrderTrackingStage stage) {
  const order = [
    OrderTrackingStage.pending,
    OrderTrackingStage.preparing,
    OrderTrackingStage.outForDelivery,
    OrderTrackingStage.delivered,
  ];

  return order.indexOf(current) >= order.indexOf(stage) &&
      current != OrderTrackingStage.unknown;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.title,
    required this.subtitle,
    required this.isLast,
    required this.isComplete,
    required this.isCurrent,
    required this.isUnknown,
  });

  final String title;
  final String subtitle;
  final bool isLast;
  final bool isComplete;
  final bool isCurrent;
  final bool isUnknown;

  @override
  Widget build(BuildContext context) {
    final activeColor = isUnknown
        ? bodyTextColor
        : (isCurrent
            ? primaryColor
            : (isComplete ? const Color(0xFF1E8E3E) : const Color(0xFFD1D5DB)));

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : defaultPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                height: 20,
                width: 20,
                decoration: BoxDecoration(
                  color: isComplete || isCurrent ? activeColor : Colors.white,
                  border: Border.all(color: activeColor, width: 2),
                  shape: BoxShape.circle,
                ),
                child: isComplete
                    ? const Icon(Icons.check_rounded,
                        size: 12, color: Colors.white)
                    : isCurrent
                        ? const Icon(Icons.near_me_rounded,
                            size: 12, color: Colors.white)
                        : null,
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 42,
                  margin: const EdgeInsets.only(top: 6),
                  color: isComplete ? activeColor : const Color(0xFFE5E7EB),
                ),
            ],
          ),
          const SizedBox(width: defaultPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: bodyTextColor,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderDetailCard extends StatelessWidget {
  const _OrderDetailCard({required this.tracking});

  final OrderTrackingUpdate tracking;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _DetailTile(
        icon: Icons.receipt_long_rounded,
        label: 'Tracking ID',
        value: tracking.orderId,
      ),
      _DetailTile(
        icon: Icons.timer_outlined,
        label: 'ETA',
        value: tracking.hasLiveMovement ? 'Updating soon' : 'Not available yet',
      ),
      _DetailTile(
        icon: Icons.person_pin_circle_rounded,
        label: 'Courier',
        value: tracking.hasLocation
            ? 'Live location available'
            : 'Waiting for assignment',
      ),
      _DetailTile(
        icon: Icons.map_outlined,
        label: 'Route',
        value: tracking.hasLocation
            ? 'Navigation active'
            : 'Tracking will update once location is shared',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF2F2F2)),
      ),
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        children: [
          for (var index = 0; index < tiles.length; index++) ...[
            tiles[index],
            if (index != tiles.length - 1)
              const SizedBox(height: defaultPadding / 1.5),
          ],
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: primaryColor),
        ),
        const SizedBox(width: defaultPadding),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: bodyTextColor,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrackingMapCard extends StatelessWidget {
  const _TrackingMapCard({required this.tracking});

  final OrderTrackingUpdate tracking;

  @override
  Widget build(BuildContext context) {
    final location = _trackingLocation(tracking);
    final mapNotReady = !tracking.hasLocation;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF2F2F2)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!tracking.hasLocation)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(defaultPadding),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4EC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.gps_off_rounded,
                      size: 18,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: defaultPadding / 2),
                  Expanded(
                    child: Text(
                      'Live location is not available yet. Showing the last known area instead.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.35,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 1.15,
              child: mapNotReady
                  ? Container(
                      color: const Color(0xFFF7F7F7),
                      padding: const EdgeInsets.all(defaultPadding),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 56,
                            width: 56,
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.map_outlined,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: defaultPadding / 2),
                          Text(
                            'Map preview will appear once live location is shared.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: bodyTextColor,
                                  height: 1.4,
                                ),
                          ),
                        ],
                      ),
                    )
                  : GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: location,
                        zoom: 13.5,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('order'),
                          position: location,
                          infoWindow: InfoWindow(
                            title: 'Order ${tracking.orderId}',
                            snippet: tracking.statusLabel,
                          ),
                        ),
                      },
                      polylines: {
                        Polyline(
                          polylineId: const PolylineId('route'),
                          points:
                              const [_fallbackCenter, _fallbackCenter].toList()
                                ..[1] = location,
                          color: primaryColor,
                          width: 4,
                        ),
                      },
                      myLocationEnabled: false,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: bodyTextColor,
                height: 1.4,
              ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _MiniInfoTile extends StatelessWidget {
  const _MiniInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding / 1.25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withOpacity(0.78),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
          ),
        ],
      ),
    );
  }
}

class _TrackingLoadingState extends StatelessWidget {
  const _TrackingLoadingState();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LoadingCard(height: 186),
          SizedBox(height: defaultPadding),
          _LoadingCard(height: 220),
          SizedBox(height: defaultPadding),
          _LoadingCard(height: 210),
          SizedBox(height: defaultPadding),
          _LoadingCard(height: 280),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 24, width: 150, color: Colors.white),
          const SizedBox(height: 12),
          Container(height: 14, width: 210, color: Colors.white),
          const SizedBox(height: 24),
          Expanded(
            child: Column(
              children: List.generate(
                3,
                (index) => Padding(
                  padding: EdgeInsets.only(bottom: index == 2 ? 0 : 12),
                  child: Row(
                    children: [
                      Container(
                        height: 18,
                        width: 18,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: defaultPadding),
                      Expanded(
                        child: Container(
                          height: 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingErrorState extends StatelessWidget {
  const _TrackingErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(defaultPadding),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF2F2F2)),
          ),
          padding: const EdgeInsets.all(defaultPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delivery_dining_rounded,
                  color: primaryColor,
                  size: 36,
                ),
              ),
              const SizedBox(height: defaultPadding),
              Text(
                'Tracking is taking a break',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: bodyTextColor,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: defaultPadding * 1.5),
              PrimaryButton(
                text: 'Try again',
                press: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _iconForStage(OrderTrackingStage stage) {
  switch (stage) {
    case OrderTrackingStage.pending:
      return Icons.receipt_long_rounded;
    case OrderTrackingStage.preparing:
      return Icons.kitchen_rounded;
    case OrderTrackingStage.outForDelivery:
      return Icons.delivery_dining_rounded;
    case OrderTrackingStage.delivered:
      return Icons.verified_rounded;
    case OrderTrackingStage.unknown:
      return Icons.local_shipping_rounded;
  }
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  final month = _monthName(local.month);
  return '$month ${local.day}, $hour:$minute $period';
}

String _monthName(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return months[(month - 1).clamp(0, months.length - 1)];
}
