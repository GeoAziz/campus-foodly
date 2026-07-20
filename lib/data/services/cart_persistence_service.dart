import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../models/cart_item.dart';

final _logger = Logger();

/// Handles persistence of cart items to local device storage
/// Supports versioning and schema migration
class CartPersistenceService {
  static const String _cartKey = 'app_cart_items';
  static const int _currentVersion = 1;

  late final SharedPreferences _prefs;

  CartPersistenceService(this._prefs);

  /// Initialize the service and load persisted cart if available
  static Future<CartPersistenceService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return CartPersistenceService(prefs);
  }

  /// Save cart items to local storage with versioning
  Future<void> saveCart(List<CartItem> items) async {
    try {
      final jsonList = items.map((item) => item.toJson()).toList();
      final cartData = {
        'version': _currentVersion,
        'items': jsonList,
        'timestamp': DateTime.now().toIso8601String(),
        'itemCount': items.length,
      };

      final jsonString = jsonEncode(cartData);

      // Note: For production, consider using encrypted_shared_preferences
      // for sensitive cart data. Update this when ready:
      // await _encryptedPrefs.setString(_cartKey, jsonString);
      await _prefs.setString(_cartKey, jsonString);
      _logger.d('[CartPersistence] Saved ${items.length} items');
    } catch (e) {
      _logger.e('[CartPersistence] Error saving cart: $e');
      rethrow;
    }
  }

  /// Load cart items from local storage with version migration
  Future<List<CartItem>> loadCart() async {
    try {
      final jsonString = _prefs.getString(_cartKey);
      if (jsonString == null) {
        _logger.d('[CartPersistence] No persisted cart found');
        return [];
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final version = json['version'] as int? ?? 0;

      // Handle version migration
      if (version < _currentVersion) {
        _logger.w(
          '[CartPersistence] Cart version $version < current $_currentVersion. '
          'Migrating...',
        );
        return await _migrateCart(json, version);
      }

      if (version > _currentVersion) {
        _logger.w(
          '[CartPersistence] Cart version $version > current $_currentVersion. '
          'Clearing cache for safety.',
        );
        await clearCart();
        return [];
      }

      final items = (json['items'] as List<dynamic>?)
              ?.map((item) => CartItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [];

      _logger.d('[CartPersistence] Loaded ${items.length} items from storage');
      return items;
    } catch (e) {
      _logger.e('[CartPersistence] Error loading cart: $e');
      return [];
    }
  }

  /// Handle schema migration between versions
  Future<List<CartItem>> _migrateCart(
    Map<String, dynamic> cartData,
    int fromVersion,
  ) async {
    try {
      if (fromVersion == 0) {
        // v0 -> v1: No changes yet, just ensure version is set
        _logger.i('[CartPersistence] Migrating from v0 to v1');
        cartData['version'] = _currentVersion;
        cartData['timestamp'] = DateTime.now().toIso8601String();

        final items = (cartData['items'] as List<dynamic>?)
                ?.map((item) => CartItem.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [];

        // Resave with new version
        await saveCart(items);
        return items;
      }

      // Unknown version - clear for safety
      _logger.w('[CartPersistence] Unknown version $fromVersion. Clearing cart.');
      await clearCart();
      return [];
    } catch (e) {
      _logger.e('[CartPersistence] Error during migration: $e');
      await clearCart();
      return [];
    }
  }

  /// Clear all persisted cart data
  Future<void> clearCart() async {
    try {
      await _prefs.remove(_cartKey);
      _logger.d('[CartPersistence] Cart cleared');
    } catch (e) {
      _logger.e('[CartPersistence] Error clearing cart: $e');
      rethrow;
    }
  }

  /// Check if there's a persisted cart
  bool hasPersistentCart() {
    return _prefs.containsKey(_cartKey);
  }

  /// Get the timestamp of the last saved cart
  DateTime? getLastSaveTime() {
    try {
      final jsonString = _prefs.getString(_cartKey);
      if (jsonString == null) return null;

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final timestamp = json['timestamp'] as String?;
      if (timestamp == null) return null;

      return DateTime.tryParse(timestamp);
    } catch (e) {
      _logger.e('Error getting last save time: $e');
      return null;
    }
  }

  /// Get item count from cache without loading full cart
  int? getCachedItemCount() {
    try {
      final jsonString = _prefs.getString(_cartKey);
      if (jsonString == null) return null;

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return json['itemCount'] as int?;
    } catch (e) {
      _logger.e('Error getting item count: $e');
      return null;
    }
  }
}
