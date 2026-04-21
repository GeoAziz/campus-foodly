import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ordereats/data/models/app_user.dart';
import 'package:ordereats/data/providers/auth_provider.dart';
import 'package:ordereats/features/profile/models/address.dart';
import 'package:ordereats/features/profile/models/notification_preference.dart';
import 'package:ordereats/features/profile/models/payment_method.dart';
import 'package:ordereats/features/profile/models/profile_data.dart';
import 'package:ordereats/features/profile/models/social_account.dart';
import 'package:ordereats/features/profile/presentation/profile_edit_screen.dart';
import 'package:ordereats/features/profile/providers/profile_provider.dart';
import 'package:ordereats/features/profile/repositories/profile_repository.dart';

void main() {
  group('ProfileEditScreen', () {
    testWidgets('renders profile data in view mode', (tester) async {
      final repository = FakeProfileRepository();

      await pumpProfileEditScreen(tester, repository);
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsNWidgets(2));
      expect(find.text('Alice Doe'), findsOneWidget);
      expect(find.text('555-1111'), findsOneWidget);
      expect(find.text('Food lover'), findsOneWidget);
      expect(find.text('Save Changes'), findsNothing);
    });

    testWidgets('enters edit mode and shows save/cancel actions',
        (tester) async {
      final repository = FakeProfileRepository();

      await pumpProfileEditScreen(tester, repository);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Edit Profile'));
      await tester.pumpAndSettle();

      expect(
          find.widgetWithText(ElevatedButton, 'Save Changes'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Cancel'), findsOneWidget);
    });

    testWidgets('saves updated profile and shows success feedback',
        (tester) async {
      final repository = FakeProfileRepository();

      await pumpProfileEditScreen(tester, repository);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Edit Profile'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Full Name'), 'Alice Updated');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Phone Number'), '555-7777');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Tell us about yourself'),
          'Updated bio');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
      await tester.pumpAndSettle();

      expect(repository.updateProfileCalls, 1);
      expect(repository.lastUpdatedProfile?.displayName, 'Alice Updated');
      expect(repository.lastUpdatedProfile?.phone, '555-7777');
      expect(repository.lastUpdatedProfile?.bio, 'Updated bio');
      expect(find.text('Profile updated successfully'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    });

    testWidgets('shows repository error when save fails', (tester) async {
      final repository = FakeProfileRepository(shouldFailUpdate: true);

      await pumpProfileEditScreen(tester, repository);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Edit Profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Profile Error:'), findsOneWidget);
    });

    testWidgets('cancel discards unsaved edits', (tester) async {
      final repository = FakeProfileRepository();

      await pumpProfileEditScreen(tester, repository);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Edit Profile'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Full Name'), 'Unsaved Name');
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Unsaved Name'), findsNothing);
      expect(find.text('Alice Doe'), findsOneWidget);
    });
  });
}

Future<void> pumpProfileEditScreen(
  WidgetTester tester,
  FakeProfileRepository repository,
) async {
  final user = const AppUser(
    id: 'user-1',
    email: 'alice@example.com',
    displayName: 'Alice Doe',
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => TestAuthController(user)),
        profileRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(home: ProfileEditScreen()),
    ),
  );
}

class TestAuthController extends AuthController {
  TestAuthController(this._user);

  final AppUser _user;

  @override
  Future<AppUser?> build() async {
    return _user;
  }
}

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({this.shouldFailUpdate = false});

  final bool shouldFailUpdate;
  int updateProfileCalls = 0;
  ProfileData? lastUpdatedProfile;

  @override
  Future<ProfileData?> getProfile(String uid) async {
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
