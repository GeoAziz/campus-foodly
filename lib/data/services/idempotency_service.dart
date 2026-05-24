import 'package:uuid/uuid.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

/// Service for managing idempotency keys to prevent duplicate operations
/// Uses local storage to track request IDs and prevent duplicates
class IdempotencyService {
  static final IdempotencyService _instance = IdempotencyService._internal();
  static final Logger _logger = Logger();
  static const String _boxName = 'idempotency_keys';
  
  late final Box<String> _idempotencyBox;
  bool _initialized = false;

  factory IdempotencyService() {
    return _instance;
  }

  IdempotencyService._internal();

  /// Initialize the idempotency service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _idempotencyBox = await Hive.openBox<String>(_boxName);
      _logger.i('IdempotencyService initialized');
      _initialized = true;
      
      // Clean up old keys (older than 24 hours)
      await _cleanupOldKeys();
    } catch (e) {
      _logger.e('Failed to initialize IdempotencyService: $e');
      rethrow;
    }
  }

  /// Generate a new idempotency key (UUID v4)
  String generateKey() {
    const uuid = Uuid();
    return uuid.v4();
  }

  /// Store an idempotency key with a timestamp
  Future<void> storeKey(String key) async {
    try {
      await _idempotencyBox.put(key, DateTime.now().toIso8601String());
      _logger.d('Idempotency key stored: $key');
    } catch (e) {
      _logger.e('Failed to store idempotency key: $e');
    }
  }

  /// Check if an idempotency key has been used (within timeframe)
  bool hasKey(String key) {
    return _idempotencyBox.containsKey(key);
  }

  /// Get stored key with timestamp if exists
  String? getKeyTimestamp(String key) {
    return _idempotencyBox.get(key);
  }

  /// Check if key is valid (exists and not too old)
  bool isKeyValid(String key, {Duration maxAge = const Duration(hours: 24)}) {
    final timestamp = _idempotencyBox.get(key);
    if (timestamp == null) return false;

    try {
      final keyTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      return now.difference(keyTime) < maxAge;
    } catch (e) {
      _logger.e('Invalid timestamp format: $e');
      return false;
    }
  }

  /// Remove an idempotency key
  Future<void> removeKey(String key) async {
    try {
      await _idempotencyBox.delete(key);
      _logger.d('Idempotency key removed: $key');
    } catch (e) {
      _logger.e('Failed to remove idempotency key: $e');
    }
  }

  /// Clean up old keys (older than specified duration)
  Future<void> _cleanupOldKeys({Duration maxAge = const Duration(hours: 24)}) async {
    try {
      final keysToRemove = <String>[];
      final now = DateTime.now();

      for (var entry in _idempotencyBox.toMap().entries) {
        try {
          final keyTime = DateTime.parse(entry.value);
          if (now.difference(keyTime) > maxAge) {
            keysToRemove.add(entry.key);
          }
        } catch (e) {
          _logger.w('Invalid key timestamp: ${entry.value}');
          keysToRemove.add(entry.key);
        }
      }

      for (var key in keysToRemove) {
        await _idempotencyBox.delete(key);
      }

      _logger.i('Cleaned up ${keysToRemove.length} old idempotency keys');
    } catch (e) {
      _logger.e('Failed to cleanup old keys: $e');
    }
  }

  /// Get all stored keys (for debugging)
  Map<String, String> getAllKeys() {
    return Map<String, String>.from(_idempotencyBox.toMap());
  }

  /// Clear all keys
  Future<void> clearAll() async {
    try {
      await _idempotencyBox.clear();
      _logger.i('All idempotency keys cleared');
    } catch (e) {
      _logger.e('Failed to clear idempotency keys: $e');
    }
  }
}
