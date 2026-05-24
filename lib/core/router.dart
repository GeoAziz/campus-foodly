import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../entry_point.dart';
import '../features/order_tracking/presentation/order_delivered_screen.dart';
import '../features/order_tracking/presentation/order_tracking_screen.dart';
import '../features/payments/presentation/payment_checkout_screen.dart';
import '../features/profile/presentation/profile_edit_screen.dart';
import '../features/profile/presentation/profile_password_screen.dart';
import '../features/profile/presentation/profile_addresses_screen.dart';
import '../features/profile/presentation/profile_address_add_screen.dart';
import '../features/profile/presentation/profile_payment_methods_screen.dart';
import '../features/profile/presentation/profile_notifications_screen.dart';
import '../features/profile/presentation/profile_social_screen.dart';
import '../screens/add_to_order/add_to_order_screen.dart';
import '../screens/auth/auth_error_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/reset_email_sent_screen.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/details/details_screen.dart';
import '../screens/featured/featured_screen.dart';
import '../screens/filter/filter_screen.dart';
import '../screens/find_restaurants/find_restaurants_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/order_details/order_details_screen.dart';
import '../screens/phone_login/number_verify_screen.dart';
import '../screens/phone_login/phone_login_screen.dart';
import '../screens/search/search_screen.dart';
import '../data/models/restaurant.dart';
import '../data/providers/auth_provider.dart';
import '../data/providers/role_based_access_provider.dart';
import 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final userRole = ref.watch(userRoleProvider);

  const authRoutes = <String>{
    '/sign-in',
    '/sign-up',
    '/forgot-password',
    '/reset-email-sent',
    '/phone-login',
    '/number-verify',
    '/onboarding',
  };

  const publicRoutes = <String>{
    ...authRoutes,
    '/auth-error',
  };

  const adminRoutes = <String>{
    '/admin',
    '/admin/dashboard',
    '/admin/orders',
    '/admin/restaurants',
  };

  return GoRouter(
    initialLocation: '/onboarding',
    redirect: (context, state) {
      final user = authState.valueOrNull;
      final location = state.matchedLocation;
      final isAuthRoute = authRoutes.contains(location);
      final isPublicRoute = publicRoutes.contains(location);
      final isAdminRoute =
          adminRoutes.any((route) => location.startsWith(route));

      if (authState.hasError && location != '/auth-error') {
        return '/auth-error';
      }

      if (!authState.hasError && location == '/auth-error') {
        return '/sign-in';
      }

      // Check admin route access
      if (isAdminRoute && user != null) {
        if (!RoleBasedAccessControl.canAccessRoute(location, userRole)) {
          return '/app'; // Redirect to home if no permission
        }
      }

      if (user != null && isAuthRoute) {
        return '/app';
      }

      if (user == null && !isPublicRoute) {
        return '/sign-in';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        name: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/app',
        name: AppRoutes.app,
        builder: (context, state) => const EntryPoint(),
      ),
      GoRoute(
        path: '/sign-in',
        name: AppRoutes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/sign-up',
        name: AppRoutes.signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-email-sent',
        name: AppRoutes.resetEmailSent,
        builder: (context, state) => ResetEmailSentScreen(
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),
      GoRoute(
        path: '/auth-error',
        name: AppRoutes.authError,
        builder: (context, state) => const AuthErrorScreen(),
      ),
      GoRoute(
        path: '/phone-login',
        name: AppRoutes.phoneLogin,
        builder: (context, state) => const PhoneLoginScreen(),
      ),
      GoRoute(
        path: '/number-verify',
        name: AppRoutes.numberVerify,
        builder: (context, state) => const NumberVerifyScreen(),
      ),
      GoRoute(
        path: '/find-restaurants',
        name: AppRoutes.findRestaurants,
        builder: (context, state) => const FindRestaurantsScreen(),
      ),
      GoRoute(
        path: '/filter',
        name: AppRoutes.filter,
        builder: (context, state) => const FilterScreen(),
      ),
      GoRoute(
        path: '/featured',
        name: AppRoutes.featured,
        builder: (context, state) => const FeaturedScreen(),
      ),
      GoRoute(
        path: '/details',
        name: AppRoutes.details,
        builder: (context, state) => DetailsScreen(
          restaurant:
              state.extra is Restaurant ? state.extra as Restaurant : null,
        ),
      ),
      GoRoute(
        path: '/search',
        name: AppRoutes.search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/add-to-order',
        name: AppRoutes.addToOrder,
        builder: (context, state) => const AddToOrderScreen(),
      ),
      GoRoute(
        path: '/order-details',
        name: AppRoutes.orderDetails,
        builder: (context, state) => const OrderDetailsScreen(),
      ),
      GoRoute(
        path: '/order-tracking/:orderId',
        name: AppRoutes.orderTracking,
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return OrderTrackingScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/order-delivered/:orderId',
        name: AppRoutes.orderDelivered,
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return OrderDeliveredScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/payment-checkout',
        name: AppRoutes.paymentCheckout,
        builder: (context, state) {
          final orderId = state.uri.queryParameters['orderId'] ?? '';
          final amount =
              double.tryParse(state.uri.queryParameters['amount'] ?? '') ?? 0;
          return PaymentCheckoutScreen(orderId: orderId, amount: amount);
        },
      ),
      // Profile Routes
      GoRoute(
        path: '/profile-edit',
        name: AppRoutes.profileEdit,
        builder: (context, state) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: '/profile-password',
        name: AppRoutes.profilePassword,
        builder: (context, state) => const ProfilePasswordScreen(),
      ),
      GoRoute(
        path: '/profile-addresses',
        name: AppRoutes.profileAddresses,
        builder: (context, state) => const ProfileAddressesScreen(),
      ),
      GoRoute(
        path: '/profile-address-add',
        name: AppRoutes.profileAddressAdd,
        builder: (context, state) {
          final addressId = state.uri.queryParameters['addressId'];
          return ProfileAddressAddScreen(addressId: addressId);
        },
      ),
      GoRoute(
        path: '/profile-payment-methods',
        name: AppRoutes.profilePaymentMethods,
        builder: (context, state) => const ProfilePaymentMethodsScreen(),
      ),
      GoRoute(
        path: '/profile-notifications',
        name: AppRoutes.profileNotifications,
        builder: (context, state) => const ProfileNotificationsScreen(),
      ),
      GoRoute(
        path: '/profile-social',
        name: AppRoutes.profileSocial,
        builder: (context, state) => const ProfileSocialScreen(),
      ),
    ],
  );
});
