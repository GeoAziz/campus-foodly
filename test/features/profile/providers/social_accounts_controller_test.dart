import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ordereats/features/profile/models/address.dart';
import 'package:ordereats/features/profile/models/notification_preference.dart';
import 'package:ordereats/features/profile/models/payment_method.dart';
import 'package:ordereats/features/profile/models/profile_data.dart';
import 'package:ordereats/features/profile/models/social_account.dart';
import 'package:ordereats/features/profile/providers/profile_provider.dart';
import 'package:ordereats/features/profile/providers/social_accounts_controller.dart';
import 'package:ordereats/features/profile/repositories/profile_repository.dart';

void main() {
  group('SocialAccountsController', () {
    test('loads existing accounts on initialization', () async {
      final repository = FakeProfileRepository(
        socialAccounts: const [
          SocialAccount(provider: 'google', uid: 'google-1', email: 'a@b.com'),
        ],
      );
      final container = ProviderContainer(
        overrides: [
          profileRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(
        socialAccountsControllerProvider('user-1').notifier,
      );

      await pumpController();

      expect(
          container.read(socialAccountsControllerProvider('user-1')).accounts,
          hasLength(1));
      expect(
        container
            .read(socialAccountsControllerProvider('user-1'))
            .isProviderLinked('google'),
        isTrue,
      );
      expect(
        container
            .read(socialAccountsControllerProvider('user-1'))
            .getLinkedAccount('google')
            ?.email,
        'a@b.com',
      );
      expect(controller.state.isLoading, isFalse);
    });

    test('linkAccount replaces an existing provider entry', () async {
      final repository = FakeProfileRepository(
        socialAccounts: const [
          SocialAccount(
              provider: 'google', uid: 'old', email: 'old@example.com'),
        ],
      );
      final container = ProviderContainer(
        overrides: [
          profileRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await pumpController();

      final controller = container.read(
        socialAccountsControllerProvider('user-1').notifier,
      );
      await controller.linkAccount(
        'google',
        const SocialAccount(
            provider: 'google', uid: 'new', email: 'new@example.com'),
      );

      final state = container.read(socialAccountsControllerProvider('user-1'));
      expect(state.accounts, hasLength(1));
      expect(state.getLinkedAccount('google')?.uid, 'new');
      expect(repository.linkCalls, 1);
    });

    test('unlinkAccount removes the provider entry', () async {
      final repository = FakeProfileRepository(
        socialAccounts: const [
          SocialAccount(provider: 'google', uid: 'google-1'),
          SocialAccount(provider: 'apple', uid: 'apple-1'),
        ],
      );
      final container = ProviderContainer(
        overrides: [
          profileRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await pumpController();

      final controller = container.read(
        socialAccountsControllerProvider('user-1').notifier,
      );
      await controller.unlinkAccount('apple');

      final state = container.read(socialAccountsControllerProvider('user-1'));
      expect(state.accounts, hasLength(1));
      expect(state.isProviderLinked('apple'), isFalse);
      expect(state.isProviderLinked('google'), isTrue);
      expect(repository.unlinkCalls, 1);
    });
  });
}

Future<void> pumpController() async {
  await Future<void>.delayed(Duration.zero);
}

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({List<SocialAccount> socialAccounts = const []})
      : _socialAccounts = List.of(socialAccounts);

  final List<SocialAccount> _socialAccounts;
  int linkCalls = 0;
  int unlinkCalls = 0;

  @override
  Future<List<SocialAccount>> getSocialAccounts(String uid) async {
    return List.of(_socialAccounts);
  }

  @override
  Future<void> linkSocialAccount(String uid, SocialAccount account) async {
    linkCalls += 1;
    _socialAccounts.removeWhere((item) => item.provider == account.provider);
    _socialAccounts.add(account);
  }

  @override
  Future<void> unlinkSocialAccount(String uid, String provider) async {
    unlinkCalls += 1;
    _socialAccounts.removeWhere((item) => item.provider == provider);
  }

  @override
  Future<ProfileData?> getProfile(String uid) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateProfile(String uid, ProfileData profile) {
    throw UnimplementedError();
  }

  @override
  Future<List<Address>> getAddresses(String uid) {
    throw UnimplementedError();
  }

  @override
  Future<void> addAddress(String uid, Address address) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateAddress(String uid, Address address) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAddress(String uid, String addressId) {
    throw UnimplementedError();
  }

  @override
  Future<List<PaymentMethod>> getPaymentMethods(String uid) {
    throw UnimplementedError();
  }

  @override
  Future<void> addPaymentMethod(String uid, PaymentMethod method) {
    throw UnimplementedError();
  }

  @override
  Future<void> updatePaymentMethod(String uid, PaymentMethod method) {
    throw UnimplementedError();
  }

  @override
  Future<void> deletePaymentMethod(String uid, String paymentId) {
    throw UnimplementedError();
  }

  @override
  Future<NotificationPreference?> getNotificationPreferences(String uid) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateNotificationPreferences(
    String uid,
    NotificationPreference prefs,
  ) {
    throw UnimplementedError();
  }
}
