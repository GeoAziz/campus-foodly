import 'package:riverpod/riverpod.dart';

import '../models/notification_preference.dart';
import '../repositories/profile_repository.dart';
import 'profile_provider.dart';

class NotificationPreferencesState {
  const NotificationPreferencesState({
    this.preferences,
    this.isLoading = false,
    this.error,
    this.success = false,
  });

  final NotificationPreference? preferences;
  final bool isLoading;
  final String? error;
  final bool success;

  NotificationPreferencesState copyWith({
    NotificationPreference? preferences,
    bool? isLoading,
    String? error,
    bool? success,
  }) {
    return NotificationPreferencesState(
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      success: success ?? this.success,
    );
  }
}

class NotificationPreferencesController
    extends StateNotifier<NotificationPreferencesState> {
  NotificationPreferencesController(this._repository, this._uid)
      : super(const NotificationPreferencesState()) {
    _loadPreferences();
  }

  final ProfileRepository _repository;
  final String _uid;

  Future<void> _loadPreferences() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final prefs = await _repository.getNotificationPreferences(_uid);
      state = state.copyWith(
        isLoading: false,
        preferences: prefs ?? const NotificationPreference(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> updatePreferences(NotificationPreference preferences) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _repository.updateNotificationPreferences(_uid, preferences);
      state = state.copyWith(
        isLoading: false,
        preferences: preferences,
        success: true,
      );

      // Clear success flag after a moment
      await Future.delayed(const Duration(seconds: 2));
      state = state.copyWith(success: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void togglePushNotifications() {
    final prefs = state.preferences ?? const NotificationPreference();
    updatePreferences(
      prefs.copyWith(
        pushNotifications: !prefs.pushNotifications,
      ),
    );
  }

  void toggleOrderUpdates() {
    final prefs = state.preferences ?? const NotificationPreference();
    updatePreferences(
      prefs.copyWith(
        orderUpdates: !prefs.orderUpdates,
      ),
    );
  }

  void togglePromotions() {
    final prefs = state.preferences ?? const NotificationPreference();
    updatePreferences(
      prefs.copyWith(
        promotions: !prefs.promotions,
      ),
    );
  }

  void toggleNewRestaurants() {
    final prefs = state.preferences ?? const NotificationPreference();
    updatePreferences(
      prefs.copyWith(
        newRestaurants: !prefs.newRestaurants,
      ),
    );
  }

  void toggleRestaurantOffers() {
    final prefs = state.preferences ?? const NotificationPreference();
    updatePreferences(
      prefs.copyWith(
        restaurantOffers: !prefs.restaurantOffers,
      ),
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final notificationPreferencesControllerProvider = StateNotifierProvider.family<
    NotificationPreferencesController,
    NotificationPreferencesState,
    String>((ref, uid) {
  final repository = ref.watch(profileRepositoryProvider);
  return NotificationPreferencesController(repository, uid);
});
