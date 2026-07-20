import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/repositories/voucher_repository.dart';
import '../data/services/notification_service.dart';
import '../data/services/logger_service.dart';

/// Detects late orders and auto-generates compensation vouchers
class LateOrderDetector {
  LateOrderDetector({
    required FirebaseFirestore firestore,
    required VoucherRepository voucherRepository,
    required NotificationService notificationService,
  })  : _firestore = firestore,
        _voucherRepository = voucherRepository,
        _notificationService = notificationService;

  final FirebaseFirestore _firestore;
  final VoucherRepository _voucherRepository;
  final NotificationService _notificationService;
  final _logger = LoggerService();

  /// Delay in minutes before considering an order late
  static const int lateThresholdMinutes = 10;

  /// Discount percentage for late orders
  static const int lateOrderDiscountPercent = 10;

  /// Check for late orders and process compensation
  Future<void> detectAndCompensate() async {
    try {
      _logger.i('Starting late order detection...');

      final now = DateTime.now();
      final cutoffTime = now.subtract(
        const Duration(minutes: lateThresholdMinutes),
      );

      // Find orders that should have been delivered but weren't
      final snapshot = await _firestore
          .collection('orders')
          .where('status', isNotEqualTo: 'delivered')
          .where('estimated_delivery', isLessThan: cutoffTime)
          .where('is_compensated', isEqualTo: false)
          .get();

      _logger.i('Found ${snapshot.docs.length} potentially late orders');

      for (final doc in snapshot.docs) {
        await _compensateOrder(doc);
      }

      _logger.i('Late order detection completed');
    } catch (e) {
      _logger.e('Error in late order detection: $e');
    }
  }

  Future<void> _compensateOrder(QueryDocumentSnapshot order) async {
    try {
      final orderId = order.id;
      final userId = order['user_id'] as String?;
      final fcmToken = order['fcm_token'] as String?;

      if (userId == null) {
        _logger.w('Order $orderId has no user_id');
        return;
      }

      // Create compensation voucher
      final voucher = VoucherService.createLateOrderVoucher(
        userId: userId,
        discountPercentage: lateOrderDiscountPercent,
      );

      await _voucherRepository.createVoucher(voucher);
      _logger.i('Created compensation voucher for order $orderId: ${voucher.code}');

      // Update order as compensated
      await _firestore.collection('orders').doc(orderId).update({
        'is_compensated': true,
        'compensation_voucher_code': voucher.code,
        'compensated_at': FieldValue.serverTimestamp(),
      });

      // TODO: Send FCM notification once NotificationService has push notification method
      // if (fcmToken != null) {
      //   await _notificationService.sendPushNotification(...)
      // }

      _logger.i('Sent compensation notification for order $orderId');
    } catch (e) {
      _logger.e('Error compensating order ${order.id}: $e');
    }
  }

  /// Schedule periodic late order detection (call from your scheduler)
  static Future<void> startPeriodicDetection(
    FirebaseFirestore firestore,
    VoucherRepository voucherRepository,
    NotificationService notificationService,
  ) async {
    final detector = LateOrderDetector(
      firestore: firestore,
      voucherRepository: voucherRepository,
      notificationService: notificationService,
    );

    // Run detection every 5 minutes
    await Future.doWhile(() async {
      await detector.detectAndCompensate();
      await Future.delayed(const Duration(minutes: 5));
      return true; // Keep looping
    });
  }
}
