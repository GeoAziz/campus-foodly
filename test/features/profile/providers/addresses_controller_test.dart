import 'package:flutter_test/flutter_test.dart';

import 'package:ordereats/features/profile/models/address.dart';
import 'package:ordereats/features/profile/models/notification_preference.dart';
import 'package:ordereats/features/profile/models/payment_method.dart';
import 'package:ordereats/features/profile/models/profile_data.dart';
import 'package:ordereats/features/profile/models/social_account.dart';
import 'package:ordereats/features/profile/providers/addresses_controller.dart';
import 'package:ordereats/features/profile/repositories/profile_repository.dart';

void main() {
  group('AddressesController', () {
    test('addAddress generates an ID when one is missing', () async {
      final repository = FakeProfileRepository();
      final controller = AddressesController(repository, 'user-1');

      await pumpAsync();

      await controller.addAddress(
        const Address(
          id: '',
          label: 'Home',
          street: '12 Market St',
          city: 'Nairobi',
          state: 'Nairobi County',
          zipCode: '00100',
        ),
      );

      expect(repository.addedAddresses, hasLength(1));
      expect(repository.addedAddresses.single.id, isNotEmpty);
      expect(controller.state.addresses.single.id, isNotEmpty);
      expect(controller.state.error, isNull);
    });

    test('addAddress preserves an existing ID', () async {
      final repository = FakeProfileRepository();
      final controller = AddressesController(repository, 'user-1');

      await pumpAsync();

      await controller.addAddress(
        const Address(
          id: 'address-1',
          label: 'Work',
          street: '100 Business Rd',
          city: 'Nairobi',
          state: 'Nairobi County',
          zipCode: '00200',
        ),
      );

      expect(repository.addedAddresses.single.id, 'address-1');
      expect(controller.state.addresses.single.id, 'address-1');
    });

    test('setDefaultAddress updates the selected flag in storage state',
        () async {
      final repository = FakeProfileRepository(
        addresses: const [
          Address(
            id: 'home-1',
            label: 'Home',
            street: '12 Market St',
            city: 'Nairobi',
            state: 'Nairobi County',
            zipCode: '00100',
          ),
          Address(
            id: 'work-1',
            label: 'Work',
            street: '100 Business Rd',
            city: 'Nairobi',
            state: 'Nairobi County',
            zipCode: '00200',
          ),
        ],
      );
      final controller = AddressesController(repository, 'user-1');

      await pumpAsync();
      await controller.setDefaultAddress('work-1');

      expect(
        controller.state.addresses
            .firstWhere((address) => address.id == 'work-1')
            .isDefault,
        isTrue,
      );
      expect(
        controller.state.addresses
            .firstWhere((address) => address.id == 'home-1')
            .isDefault,
        isFalse,
      );
    });
  });
}

Future<void> pumpAsync() async {
  await Future<void>.delayed(Duration.zero);
}

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({List<Address> addresses = const []})
      : addresses = List.of(addresses);

  final List<Address> addresses;
  final List<Address> addedAddresses = [];

  @override
  Future<List<Address>> getAddresses(String uid) async {
    return List.of(addresses);
  }

  @override
  Future<void> addAddress(String uid, Address address) async {
    addedAddresses.add(address);
    addresses.add(address);
  }

  @override
  Future<void> updateAddress(String uid, Address address) async {
    final index = addresses.indexWhere((item) => item.id == address.id);
    if (index >= 0) {
      addresses[index] = address;
    }
  }

  @override
  Future<void> deleteAddress(String uid, String addressId) async {
    addresses.removeWhere((item) => item.id == addressId);
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

  @override
  Future<List<SocialAccount>> getSocialAccounts(String uid) {
    throw UnimplementedError();
  }

  @override
  Future<void> linkSocialAccount(String uid, SocialAccount account) {
    throw UnimplementedError();
  }

  @override
  Future<void> unlinkSocialAccount(String uid, String provider) {
    throw UnimplementedError();
  }
}
