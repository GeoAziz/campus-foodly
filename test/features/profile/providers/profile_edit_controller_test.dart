import 'package:flutter_test/flutter_test.dart';

import 'package:ordereats/features/profile/models/address.dart';
import 'package:ordereats/features/profile/models/notification_preference.dart';
import 'package:ordereats/features/profile/models/payment_method.dart';
import 'package:ordereats/features/profile/models/profile_data.dart';
import 'package:ordereats/features/profile/models/social_account.dart';
import 'package:ordereats/features/profile/providers/profile_edit_controller.dart';
import 'package:ordereats/features/profile/repositories/profile_repository.dart';

void main() {
  group('ProfileEditController', () {
    test('initializes in view mode and loads profile data', () async {
      final repository = FakeProfileRepository();
      final controller = ProfileEditController(repository, 'user-1');

      await pumpAsync();

      expect(controller.state.mode, ProfileEditMode.view);
      expect(controller.state.profileData?.email, 'alice@example.com');
      expect(controller.state.displayName, 'Alice Doe');
      expect(controller.state.phone, '555-1111');
      expect(controller.state.bio, 'Food lover');
      expect(controller.state.error, isNull);
    });

    test('enterEditMode and field updates change state values', () async {
      final repository = FakeProfileRepository();
      final controller = ProfileEditController(repository, 'user-1');

      await pumpAsync();

      controller.enterEditMode();
      controller.updateDisplayName('Alice Updated');
      controller.updatePhone('555-7777');
      controller.updateBio('Updated bio');

      expect(controller.state.mode, ProfileEditMode.edit);
      expect(controller.state.displayName, 'Alice Updated');
      expect(controller.state.phone, '555-7777');
      expect(controller.state.bio, 'Updated bio');
    });

    test('saveProfile persists changes and returns to view mode', () async {
      final repository = FakeProfileRepository();
      final controller = ProfileEditController(repository, 'user-1');

      await pumpAsync();

      controller.enterEditMode();
      controller.updateDisplayName('Alice Updated');
      controller.updatePhone('555-7777');
      controller.updateBio('Updated bio');

      await controller.saveProfile();

      expect(repository.updateProfileCalls, 1);
      expect(repository.lastUpdatedProfile?.displayName, 'Alice Updated');
      expect(repository.lastUpdatedProfile?.phone, '555-7777');
      expect(repository.lastUpdatedProfile?.bio, 'Updated bio');
      expect(controller.state.mode, ProfileEditMode.view);
      expect(controller.state.profileData?.displayName, 'Alice Updated');
      expect(controller.state.error, isNull);
    });

    test('cancelEdit discards unsaved edits', () async {
      final repository = FakeProfileRepository();
      final controller = ProfileEditController(repository, 'user-1');

      await pumpAsync();

      controller.enterEditMode();
      controller.updateDisplayName('Unsaved Name');
      controller.cancelEdit();

      expect(controller.state.mode, ProfileEditMode.view);
      expect(controller.state.displayName, 'Alice Doe');
    });

    test('sets error state when repository update fails', () async {
      final repository = FakeProfileRepository(shouldFailUpdate: true);
      final controller = ProfileEditController(repository, 'user-1');

      await pumpAsync();

      controller.enterEditMode();
      await controller.saveProfile();

      expect(controller.state.error, contains('Profile Error:')); 
      expect(controller.state.isLoading, isFalse);
    });

    test('sets error state when initial profile load fails', () async {
      final repository = FakeProfileRepository(shouldFailGet: true);
      final controller = ProfileEditController(repository, 'user-1');

      await pumpAsync();

      expect(controller.state.profileData, isNull);
      expect(controller.state.error, contains('Profile Error:'));
    });
  });
}

Future<void> pumpAsync() async {
  await Future<void>.delayed(Duration.zero);
}

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({
    this.shouldFailGet = false,
    this.shouldFailUpdate = false,
  });

  final bool shouldFailGet;
  final bool shouldFailUpdate;
  int updateProfileCalls = 0;
  ProfileData? lastUpdatedProfile;

  @override
  Future<ProfileData?> getProfile(String uid) async {
    if (shouldFailGet) {
      throw Exception('Profile Error: simulated get failure');
    }
    return const ProfileData(
      uid: 'user-1',
      email: 'alice@example.com',
      displayName: 'Alice Doe',
      phone: '555-1111',
      bio: 'Food lover',
    );
  }

  @override
  Future<void> updateProfile(String uid, ProfileData profile) async {
    updateProfileCalls += 1;
    if (shouldFailUpdate) {
      throw Exception('Profile Error: simulated update failure');
    }
    lastUpdatedProfile = profile;
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
