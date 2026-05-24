import 'dart:async';
import 'package:flutter/foundation.dart';

/// Handles offline caching for order tracking
class OrderTrackingOfflineCache {
  static const Duration _cacheValidity = Duration(hours: 12);

  final Map<String, _CachedOrderTracking> _cache = {};

  /// Cache order tracking data with timestamp
  void cacheOrderTracking({
    required String orderId,
    required Map<String, dynamic> data,
  }) {
    _cache[orderId] = _CachedOrderTracking(
      data: data,
      timestamp: DateTime.now(),
    );
    debugPrint('[OrderTrackingCache] Cached tracking for order: $orderId');
  }

  /// Get cached order tracking if available and not expired
  Map<String, dynamic>? getCachedTracking(String orderId) {
    final cached = _cache[orderId];
    if (cached == null) return null;

    final isExpired =
        DateTime.now().difference(cached.timestamp) > _cacheValidity;
    if (isExpired) {
      _cache.remove(orderId);
      debugPrint('[OrderTrackingCache] Cache expired for order: $orderId');
      return null;
    }

    debugPrint('[OrderTrackingCache] Retrieved cached tracking for: $orderId');
    return cached.data;
  }

  /// Check if we have cached data
  bool hasCached(String orderId) => _cache.containsKey(orderId);

  /// Clear cache for specific order
  void clearOrder(String orderId) {
    _cache.remove(orderId);
  }

  /// Clear all cache
  void clearAll() {
    _cache.clear();
  }
}

class _CachedOrderTracking {
  _CachedOrderTracking({
    required this.data,
    required this.timestamp,
  });

  final Map<String, dynamic> data;
  final DateTime timestamp;
}

/// Handles retry logic for failed operations
class RetryStrategy {
  final int maxAttempts;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;

  RetryStrategy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
  });

  Future<T> execute<T>(Future<T> Function() operation) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxAttempts) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        if (attempt >= maxAttempts) {
          rethrow;
        }

        debugPrint(
          '[Retry] Attempt $attempt failed: $e. Retrying in ${delay.inSeconds}s',
        );

        await Future.delayed(delay);
        delay = Duration(
          milliseconds: (delay.inMilliseconds * backoffMultiplier).toInt(),
        );

        if (delay > maxDelay) {
          delay = maxDelay;
        }
      }
    }

    throw StateError('Max retry attempts exceeded');
  }
}

/// Exponential backoff retry strategy for network requests
class NetworkRetryHelper {
  static final RetryStrategy _defaultStrategy = RetryStrategy();

  static Future<T> retryWithBackoff<T>(
    Future<T> Function() operation, {
    RetryStrategy? strategy,
  }) async {
    return (strategy ?? _defaultStrategy).execute(operation);
  }

  /// Retry a Firestore operation
  static Future<T> retryFirestoreOperation<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
  }) async {
    final strategy = RetryStrategy(maxAttempts: maxAttempts);
    return strategy.execute(operation);
  }
}
