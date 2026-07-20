import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

/// Handles offline caching for orders, addresses, and user data
/// Persists data to Hive for offline access after app restart
class OfflineDataService {
  static final OfflineDataService _instance = OfflineDataService._internal();
  static const Duration _cacheValidity = Duration(hours: 12);

  late final Box<String> _orderCacheBox;
  late final Box<String> _addressCacheBox;
  late final Box<String> _profileCacheBox;
  bool _initialized = false;

  factory OfflineDataService() {
    return _instance;
  }

  OfflineDataService._internal();

  /// Initialize offline storage
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _orderCacheBox = await Hive.openBox<String>('offline_orders');
      _addressCacheBox = await Hive.openBox<String>('offline_addresses');
      _profileCacheBox = await Hive.openBox<String>('offline_profile');
      _initialized = true;
      _logger.i('OfflineDataService initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize OfflineDataService: $e');
      rethrow;
    }
  }

  /// Cache order data with timestamp
  Future<void> cacheOrder({
    required String orderId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _orderCacheBox.put(orderId, jsonEncode(cacheData));
      _logger.d('[OfflineCache] Cached order: $orderId');
    } catch (e) {
      _logger.e('Failed to cache order: $e');
    }
  }

  /// Get cached order if available and not expired
  Map<String, dynamic>? getCachedOrder(String orderId) {
    try {
      final cached = _orderCacheBox.get(orderId);
      if (cached == null) return null;

      final decoded = jsonDecode(cached) as Map<String, dynamic>;
      final timestamp = DateTime.parse(decoded['timestamp'] as String);

      if (DateTime.now().difference(timestamp) > _cacheValidity) {
        _orderCacheBox.delete(orderId);
        _logger.d('[OfflineCache] Order cache expired: $orderId');
        return null;
      }

      return decoded['data'] as Map<String, dynamic>;
    } catch (e) {
      _logger.e('Error retrieving cached order: $e');
      return null;
    }
  }

  /// Cache address data
  Future<void> cacheAddress({
    required String addressId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _addressCacheBox.put(addressId, jsonEncode(cacheData));
      _logger.d('[OfflineCache] Cached address: $addressId');
    } catch (e) {
      _logger.e('Failed to cache address: $e');
    }
  }

  /// Get cached address if available and not expired
  Map<String, dynamic>? getCachedAddress(String addressId) {
    try {
      final cached = _addressCacheBox.get(addressId);
      if (cached == null) return null;

      final decoded = jsonDecode(cached) as Map<String, dynamic>;
      final timestamp = DateTime.parse(decoded['timestamp'] as String);

      if (DateTime.now().difference(timestamp) > _cacheValidity) {
        _addressCacheBox.delete(addressId);
        return null;
      }

      return decoded['data'] as Map<String, dynamic>;
    } catch (e) {
      _logger.e('Error retrieving cached address: $e');
      return null;
    }
  }

  /// Cache user profile data
  Future<void> cacheProfile({required Map<String, dynamic> data}) async {
    try {
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _profileCacheBox.put('profile', jsonEncode(cacheData));
      _logger.d('[OfflineCache] Cached profile');
    } catch (e) {
      _logger.e('Failed to cache profile: $e');
    }
  }

  /// Get cached profile if available and not expired
  Map<String, dynamic>? getCachedProfile() {
    try {
      final cached = _profileCacheBox.get('profile');
      if (cached == null) return null;

      final decoded = jsonDecode(cached) as Map<String, dynamic>;
      final timestamp = DateTime.parse(decoded['timestamp'] as String);

      if (DateTime.now().difference(timestamp) > _cacheValidity) {
        _profileCacheBox.delete('profile');
        return null;
      }

      return decoded['data'] as Map<String, dynamic>;
    } catch (e) {
      _logger.e('Error retrieving cached profile: $e');
      return null;
    }
  }

  /// Clear cache for specific order
  Future<void> clearOrder(String orderId) async {
    await _orderCacheBox.delete(orderId);
  }

  /// Clear all offline data
  Future<void> clearAll() async {
    await _orderCacheBox.clear();
    await _addressCacheBox.clear();
    await _profileCacheBox.clear();
  }

  /// Get all cached orders (for debugging/admin)
  Map<String, Map<String, dynamic>?> getAllCachedOrders() {
    final result = <String, Map<String, dynamic>?>{};
    for (final key in _orderCacheBox.keys) {
      result[key as String] = getCachedOrder(key as String);
    }
    return result;
  }
}

/// Legacy in-memory cache for backwards compatibility
class OrderTrackingOfflineCache {
  static const Duration _cacheValidity = Duration(hours: 12);

  final Map<String, _CachedOrderTracking> _cache = {};
  final OfflineDataService _offlineService = OfflineDataService();

  /// Cache order tracking data with timestamp
  void cacheOrderTracking({
    required String orderId,
    required Map<String, dynamic> data,
  }) {
    _cache[orderId] = _CachedOrderTracking(
      data: data,
      timestamp: DateTime.now(),
    );
    // Also persist to offline storage
    _offlineService.cacheOrder(orderId: orderId, data: data);
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
