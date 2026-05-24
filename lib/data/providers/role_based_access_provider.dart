import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

/// Enumeration of user roles in the system
enum UserRole {
  customer('customer'),
  restaurantOwner('restaurant_owner'),
  deliveryDriver('delivery_driver'),
  admin('admin');

  const UserRole(this.value);

  final String value;

  static UserRole fromString(String? role) {
    return UserRole.values.firstWhere(
      (e) => e.value == role,
      orElse: () => UserRole.customer,
    );
  }
}

/// Role-based access control provider
final userRoleProvider = Provider<UserRole?>((ref) {
  final authState = ref.watch(authControllerProvider);

  // Return null if auth is not loaded or errored
  if (authState.isLoading || authState.hasError) {
    return null;
  }

  final user = authState.value;
  if (user == null) return null;

  // Parse role from user metadata or default to customer
  final roleString = user.role ?? 'customer';
  return UserRole.fromString(roleString);
});

/// Check if current user has specific role
final hasRoleProvider = Provider.family<bool, UserRole>((ref, requiredRole) {
  final userRole = ref.watch(userRoleProvider);
  if (userRole == null) return false;
  return userRole == requiredRole;
});

/// Check if current user has any of the specified roles
final hasAnyRoleProvider =
    Provider.family<bool, List<UserRole>>((ref, requiredRoles) {
  final userRole = ref.watch(userRoleProvider);
  if (userRole == null) return false;
  return requiredRoles.contains(userRole);
});

/// Check if current user is admin
final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(hasRoleProvider(UserRole.admin));
});

/// Check if current user is restaurant owner
final isRestaurantOwnerProvider = Provider<bool>((ref) {
  return ref.watch(hasRoleProvider(UserRole.restaurantOwner));
});

/// Check if current user is delivery driver
final isDeliveryDriverProvider = Provider<bool>((ref) {
  return ref.watch(hasRoleProvider(UserRole.deliveryDriver));
});

/// Validates user has required permission before accessing a resource
class RoleBasedAccessControl {
  static bool canAccessRoute(String route, UserRole? userRole) {
    if (userRole == null) return false;

    final adminRoutes = {
      '/admin',
      '/admin/dashboard',
      '/admin/orders',
      '/admin/restaurants',
      '/admin/users',
    };

    final restaurantOwnerRoutes = {
      '/restaurant/dashboard',
      '/restaurant/menu',
      '/restaurant/orders',
    };

    final driverRoutes = {
      '/driver/dashboard',
      '/driver/deliveries',
    };

    // Check admin routes
    if (adminRoutes.contains(route)) {
      return userRole == UserRole.admin;
    }

    // Check restaurant owner routes
    if (restaurantOwnerRoutes.contains(route)) {
      return userRole == UserRole.restaurantOwner || userRole == UserRole.admin;
    }

    // Check driver routes
    if (driverRoutes.contains(route)) {
      return userRole == UserRole.deliveryDriver || userRole == UserRole.admin;
    }

    // All customers can access public routes
    return true;
  }

  static bool canPerformAction(String action, UserRole? userRole) {
    if (userRole == null) return false;

    debugPrint(
        '[RBAC] Checking permission: $action for role: ${userRole.value}');

    switch (action) {
      case 'view_all_orders':
        return userRole == UserRole.admin;
      case 'manage_restaurants':
        return userRole == UserRole.admin ||
            userRole == UserRole.restaurantOwner;
      case 'view_restaurant_analytics':
        return userRole == UserRole.restaurantOwner ||
            userRole == UserRole.admin;
      case 'accept_delivery':
        return userRole == UserRole.deliveryDriver;
      case 'mark_order_preparing':
        return userRole == UserRole.restaurantOwner ||
            userRole == UserRole.admin;
      case 'mark_order_ready':
        return userRole == UserRole.restaurantOwner ||
            userRole == UserRole.deliveryDriver ||
            userRole == UserRole.admin;
      default:
        return false;
    }
  }
}
