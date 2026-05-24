import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Extension to help add .autoDispose to providers
/// This helps prevent memory leaks by disposing providers when not in use
extension AutoDisposeExt on Ref {
  /// Mark this ref as auto-dispose eligible
  void markAutoDispose() {
    // This is a marker for developers that this provider should use .autoDispose
    // Implementation: Add .autoDispose modifier to StateNotifierProvider declarations
  }
}

/// Documentation of providers that should have .autoDispose modifier:
///
/// CRITICAL - Already use auto-dispose (built-in):
/// - FutureProvider (auto-dispose by default)
/// - StreamProvider (auto-dispose by default)
/// - AsyncNotifierProvider (can use .autoDispose)
///
/// SHOULD use .autoDispose (currently might not):
/// - searchUiControllerProvider → prevents stale search queries
/// - addToOrderControllerProvider → clears when modal closes
/// - profileEditControllerProvider → clears when edit screen unmounts
/// - paginatedRestaurantsProvider → clears when page changes
/// - paymentControllerProvider → clears payment state on completion
/// - addressesControllerProvider → clears when screen unmounts
///
/// MUST NOT use .autoDispose (user-scoped):
/// - cartProvider → persists across navigation
/// - authControllerProvider → must persist auth state
/// - orderControllerProvider → must persist for session
/// - entryTabIndexProvider → maintains nav state
///
/// Usage pattern:
/// ```dart
/// final myProvider = StateNotifierProvider.autoDispose<MyController, MyState>(
///   (ref) => MyController(),
/// );
/// ```
///
/// This automatically disposes the provider when no longer watched,
/// freeing memory and resources.

/// Helper to identify providers needing auto-dispose updates
class AutoDisposeProviderAudit {
  static const List<String> providersNeedingAutoDispose = [
    'searchUiControllerProvider',
    'addToOrderControllerProvider',
    'profileEditControllerProvider',
    'paginatedRestaurantsProvider',
    'paymentControllerProvider',
    'addressesControllerProvider',
  ];

  static const List<String> providersKeepingState = [
    'cartProvider',
    'authControllerProvider',
    'orderControllerProvider',
    'entryTabIndexProvider',
  ];
}
