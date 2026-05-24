import 'dart:async';
import 'package:flutter/foundation.dart';

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

  /// Generate a unique request ID for address loading
  /// Returns a string that uniquely identifies this request
  String generateRequestId(String userId) {
    final id =
        '${userId}_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
    _activeRequests[userId] = id;
    return id;
  }

  /// Check if a request is still active (not superseded by a newer one)
  /// Returns true if this is the latest request for the user
  bool isRequestActive(String userId, String requestId) {
    return _activeRequests[userId] == requestId;
  }

  /// Mark a request as complete
  void completeRequest(String userId) {
    _activeRequests.remove(userId);
  }

  /// Clear all active requests (usually on logout)
  void clearAll() {
    _activeRequests.clear();
    debugPrint('[AddressLoadingService] Cleared all active requests');
  }

  /// Get stats for debugging
  Map<String, dynamic> getStats() {
    return {
      'activeRequests': _activeRequests.length,
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
