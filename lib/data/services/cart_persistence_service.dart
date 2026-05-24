import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';

/// Handles persistence of cart items to local device storage
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

  /// Save cart items to local storage
  Future<void> saveCart(List<CartItem> items) async {
    try {
      final jsonList = items.map((item) => item.toJson()).toList();
      final jsonString = jsonEncode({
        'version': _currentVersion,
        'items': jsonList,
        'timestamp': DateTime.now().toIso8601String(),
      });
      await _prefs.setString(_cartKey, jsonString);
      debugPrint('[CartPersistence] Saved ${items.length} items');
    } catch (e) {
      debugPrint('[CartPersistence] Error saving cart: $e');
      rethrow;
    }
  }

  /// Load cart items from local storage
  Future<List<CartItem>> loadCart() async {
    try {
      final jsonString = _prefs.getString(_cartKey);
      if (jsonString == null) {
        debugPrint('[CartPersistence] No persisted cart found');
        return [];
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final version = json['version'] as int? ?? 0;

      // Handle version migration if needed in future
      if (version != _currentVersion) {
        debugPrint('[CartPersistence] Cart version mismatch, clearing cache');
        await clearCart();
        return [];
      }

      final items = (json['items'] as List<dynamic>?)
              ?.map((item) => CartItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [];

      debugPrint('[CartPersistence] Loaded ${items.length} items from storage');
      return items;
    } catch (e) {
      debugPrint('[CartPersistence] Error loading cart: $e');
      // Return empty list if there's a parsing error
      return [];
    }
  }

  /// Clear all persisted cart data
  Future<void> clearCart() async {
    try {
      await _prefs.remove(_cartKey);
      debugPrint('[CartPersistence] Cart cleared');
    } catch (e) {
      debugPrint('[CartPersistence] Error clearing cart: $e');
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
      return null;
    }
  }
}
