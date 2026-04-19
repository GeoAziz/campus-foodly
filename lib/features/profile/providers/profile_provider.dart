import 'package:riverpod/riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../data/providers/auth_provider.dart';
import '../models/address.dart';
import '../models/notification_preference.dart';
import '../models/payment_method.dart';
import '../models/profile_data.dart';
import '../models/social_account.dart';
import '../repositories/profile_repository.dart';

// Profile Repository Provider
final profileRepositoryProvider = Provider((ref) {
  return ProfileRepository(FirebaseFirestore.instance);
});

// Current User's Profile Data
final userProfileProvider = FutureProvider<ProfileData?>((ref) async {
  final authState = ref.watch(authControllerProvider);
  final repository = ref.watch(profileRepositoryProvider);

  return authState.whenData((user) {
    if (user == null) {
      return null;
    }
    return repository.getProfile(user.id);
  }).value;
});

// User's Addresses
final userAddressesProvider = FutureProvider<List<Address>>((ref) async {
  final authState = ref.watch(authControllerProvider);
  final repository = ref.watch(profileRepositoryProvider);

  if (authState.isLoading || authState.value == null) {
    return [];
  }

  final user = authState.value;
  if (user == null) {
    return [];
  }

  return repository.getAddresses(user.id);
});

// User's Payment Methods
final userPaymentMethodsProvider =
    FutureProvider<List<PaymentMethod>>((ref) async {
  final authState = ref.watch(authControllerProvider);
  final repository = ref.watch(profileRepositoryProvider);

  if (authState.isLoading || authState.value == null) {
    return [];
  }

  final user = authState.value;
  if (user == null) {
    return [];
  }

  return repository.getPaymentMethods(user.id);
});

// User's Notification Preferences
final userNotificationPreferencesProvider =
    FutureProvider<NotificationPreference?>((ref) async {
  final authState = ref.watch(authControllerProvider);
  final repository = ref.watch(profileRepositoryProvider);

  if (authState.isLoading || authState.value == null) {
    return null;
  }

  final user = authState.value;
  if (user == null) {
    return null;
  }

  return repository.getNotificationPreferences(user.id);
});

// User's Social Accounts
final userSocialAccountsProvider =
    FutureProvider<List<SocialAccount>>((ref) async {
  final authState = ref.watch(authControllerProvider);
  final repository = ref.watch(profileRepositoryProvider);

  if (authState.isLoading || authState.value == null) {
    return [];
  }

  final user = authState.value;
  if (user == null) {
    return [];
  }

  return repository.getSocialAccounts(user.id);
});
