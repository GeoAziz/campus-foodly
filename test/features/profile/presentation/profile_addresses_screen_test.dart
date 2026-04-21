import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:ordereats/core/routes.dart';
import 'package:ordereats/data/models/app_user.dart';
import 'package:ordereats/data/providers/auth_provider.dart';
import 'package:ordereats/features/profile/models/address.dart';
import 'package:ordereats/features/profile/models/notification_preference.dart';
import 'package:ordereats/features/profile/models/payment_method.dart';
import 'package:ordereats/features/profile/models/profile_data.dart';
import 'package:ordereats/features/profile/models/social_account.dart';
import 'package:ordereats/features/profile/presentation/profile_addresses_screen.dart';
import 'package:ordereats/features/profile/providers/profile_provider.dart';
import 'package:ordereats/features/profile/repositories/profile_repository.dart';

void main() {
  group('ProfileAddressesScreen', () {
    testWidgets('shows empty state when there are no saved addresses',
        (tester) async {
      final repository = FakeProfileRepository(addresses: const []);

      await pumpAddressesScreen(tester, repository);

      await tester.pumpAndSettle();

      expect(find.text('No addresses yet'), findsOneWidget);
      expect(find.text('Add your first delivery address'), findsOneWidget);
    });

    testWidgets('renders address list with default badge', (tester) async {
      final repository = FakeProfileRepository(
        addresses: const [
          Address(
            id: 'home-1',
            label: 'Home',
            street: '12 Market St',
            city: 'San Francisco',
            state: 'CA',
            zipCode: '94103',
            isDefault: true,
          ),
          Address(
            id: 'work-1',
            label: 'Work',
            street: '100 First Ave',
            city: 'San Francisco',
            state: 'CA',
            zipCode: '94105',
          ),
        ],
      );

      await pumpAddressesScreen(tester, repository);
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
      expect(find.text('Default Address'), findsOneWidget);
      expect(
          find.text('12 Market St, San Francisco, CA 94103'), findsOneWidget);
    });

    testWidgets('opens add address route from FAB', (tester) async {
      final repository = FakeProfileRepository(addresses: const []);

      await pumpAddressesScreen(tester, repository);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Address Add Route'), findsOneWidget);
      expect(find.text('addressId=none'), findsOneWidget);
    });

    testWidgets('set default action updates repository', (tester) async {
      final repository = FakeProfileRepository(
        addresses: const [
          Address(
            id: 'home-1',
            label: 'Home',
            street: '12 Market St',
            city: 'San Francisco',
            state: 'CA',
            zipCode: '94103',
            isDefault: true,
          ),
          Address(
            id: 'work-1',
            label: 'Work',
            street: '100 First Ave',
            city: 'San Francisco',
            state: 'CA',
            zipCode: '94105',
          ),
        ],
      );

      await pumpAddressesScreen(tester, repository);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Set as Default'));
      await tester.pumpAndSettle();

      expect(repository.updateAddressCalls, 2);
      expect(
        repository.addresses.firstWhere((a) => a.id == 'work-1').isDefault,
        isTrue,
      );
      expect(
        repository.addresses.firstWhere((a) => a.id == 'home-1').isDefault,
        isFalse,
      );
    });

    testWidgets('delete action removes address after confirmation',
        (tester) async {
      final repository = FakeProfileRepository(
        addresses: const [
          Address(
            id: 'home-1',
            label: 'Home',
            street: '12 Market St',
            city: 'San Francisco',
            state: 'CA',
            zipCode: '94103',
          ),
        ],
      );

      await pumpAddressesScreen(tester, repository);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Address?'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(repository.deleteAddressCalls, 1);
      expect(repository.addresses, isEmpty);
      expect(find.text('No addresses yet'), findsOneWidget);
    });
  });
}

Future<void> pumpAddressesScreen(
  WidgetTester tester,
  FakeProfileRepository repository,
) async {
  final user = const AppUser(
    id: 'user-1',
    email: 'test@example.com',
    displayName: 'Test User',
  );

  final router = GoRouter(
    initialLocation: '/addresses',
    routes: [
      GoRoute(
        path: '/addresses',
        name: AppRoutes.profileAddresses,
        builder: (context, state) => const ProfileAddressesScreen(),
      ),
      GoRoute(
        path: '/address-add',
        name: AppRoutes.profileAddressAdd,
        builder: (context, state) {
          final addressId = state.uri.queryParameters['addressId'];
          return Scaffold(
            body: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Address Add Route'),
                Text('addressId=${addressId ?? 'none'}'),
              ],
            ),
          );
        },
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => TestAuthController(user)),
        profileRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp.router(routerConfig: router),
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
  FakeProfileRepository({List<Address> addresses = const []})
      : addresses = List.of(addresses);

  final List<Address> addresses;
  int updateAddressCalls = 0;
  int deleteAddressCalls = 0;

  @override
  Future<List<Address>> getAddresses(String uid) async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    return List.of(addresses);
  }

  @override
  Future<void> updateAddress(String uid, Address address) async {
    updateAddressCalls += 1;
    final index = addresses.indexWhere((a) => a.id == address.id);
    if (index >= 0) {
      addresses[index] = address;
    }
  }

  @override
  Future<void> deleteAddress(String uid, String addressId) async {
    deleteAddressCalls += 1;
    addresses.removeWhere((a) => a.id == addressId);
  }

  @override
  Future<void> addAddress(String uid, Address address) {
    throw UnimplementedError();
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
