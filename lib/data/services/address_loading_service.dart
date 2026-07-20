import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

/// Service to manage address loading and prevent race conditions
/// Ensures only the latest request completes while older requests are ignored
class AddressLoadingService {
  static final AddressLoadingService _instance =
      AddressLoadingService._internal();

  factory AddressLoadingService() {
    return _instance;
  }

  AddressLoadingService._internal();

  // Track active request IDs to ignore stale responses
  final Map<String, String> _activeRequests = {};

  // Track request creation times for automatic cleanup
  final Map<String, DateTime> _requestTimes = {};
  static const Duration _requestTimeout = Duration(minutes: 5);

  /// Generate a unique request ID for address loading
  /// Returns a string that uniquely identifies this request
  String generateRequestId(String userId) {
    final id =
        '${userId}_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
    _activeRequests[userId] = id;
    _requestTimes[id] = DateTime.now();

    // Clean up old requests
    _cleanupExpiredRequests();

    _logger.d('[AddressLoadingService] Generated request ID: $id');
    return id;
  }

  /// Check if a request is still active (not superseded by a newer one)
  /// Returns true if this is the latest request for the user
  bool isRequestActive(String userId, String requestId) {
    return _activeRequests[userId] == requestId;
  }

  /// Mark a request as complete
  void completeRequest(String userId) {
    final requestId = _activeRequests[userId];
    if (requestId != null) {
      _activeRequests.remove(userId);
      _requestTimes.remove(requestId);
      _logger.d('[AddressLoadingService] Completed request: $requestId');
    }
  }

  /// Clean up expired requests to prevent memory leaks
  void _cleanupExpiredRequests() {
    final now = DateTime.now();
    final idsToRemove = <String>[];

    _requestTimes.forEach((id, createdAt) {
      if (now.difference(createdAt) > _requestTimeout) {
        idsToRemove.add(id);
      }
    });

    for (final id in idsToRemove) {
      _requestTimes.remove(id);
      // Also remove from active requests if present
      _activeRequests.removeWhere((_, v) => v == id);
    }

    if (idsToRemove.isNotEmpty) {
      _logger.w(
        '[AddressLoadingService] Cleaned up ${idsToRemove.length} expired requests',
      );
    }
  }

  /// Clear all active requests (usually on logout)
  void clearAll() {
    _activeRequests.clear();
    _requestTimes.clear();
    _logger.d('[AddressLoadingService] Cleared all active requests');
  }

  /// Get stats for debugging
  Map<String, dynamic> getStats() {
    return {
      'activeRequests': _activeRequests.length,
      'pendingRequestIds': _requestTimes.length,
      'userIds': _activeRequests.keys.toList(),
    };
  }
}

/// Helper to wrap async address loading with race condition prevention
Future<T?> withRaceConditionPrevention<T>({
  required String userId,
  required Future<T> Function(String requestId) loadFn,
  void Function()? onRaceConditionDetected,
}) async {
  final service = AddressLoadingService();
  final requestId = service.generateRequestId(userId);

  debugPrint('[AddressLoadingService] Starting request: $requestId');

  try {
    final result = await loadFn(requestId);

    // Check if this request is still active
    if (!service.isRequestActive(userId, requestId)) {
      debugPrint(
          '[AddressLoadingService] Request $requestId was superseded by newer request');
      onRaceConditionDetected?.call();
      return null;
    }

    service.completeRequest(userId);
    debugPrint(
        '[AddressLoadingService] Request $requestId completed successfully');
    return result;
  } catch (e) {
    debugPrint('[AddressLoadingService] Request $requestId failed: $e');
    service.completeRequest(userId);
    rethrow;
  }
}
