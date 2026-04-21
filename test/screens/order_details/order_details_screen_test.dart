import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ordereats/data/models/app_user.dart';
import 'package:ordereats/data/models/order.dart';
import 'package:ordereats/data/models/order_item.dart';
import 'package:ordereats/data/providers/auth_provider.dart';
import 'package:ordereats/data/providers/order_provider.dart';
import 'package:ordereats/data/repositories/order_repository.dart';
import 'package:ordereats/screens/order_details/order_details_screen.dart';

void main() {
  group('OrderDetailsScreen', () {
    testWidgets('shows order history even when cart is empty', (tester) async {
      final repository = InMemoryOrderRepository();
      await repository.saveOrder(
        Order(
          id: 'order-1',
          userId: 'user-1',
          restaurantId: 'rest-1',
          status: 'pending',
          createdAt: DateTime(2026, 4, 20, 10, 30),
          items: const [
            OrderItem(
              id: 'item-1',
              name: 'Burger',
              quantity: 2,
              unitPrice: 9.5,
            ),
          ],
          deliveryAddressId: 'addr-1',
          deliveryAddressLabel: 'Home',
          deliveryAddressLine: '123 Main St',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(
              () => TestAuthController(
                const AppUser(
                  id: 'user-1',
                  email: 'test@example.com',
                  displayName: 'Test User',
                ),
              ),
            ),
            orderRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            home: OrderDetailsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      expect(find.text('Order History'), findsOneWidget);
      expect(find.text('Current Cart'), findsOneWidget);
      expect(find.textContaining('Order order-1'), findsOneWidget);
      expect(find.textContaining('Burger'), findsOneWidget);
      expect(
        find.text('Your cart is empty. Add a dish to continue.'),
        findsOneWidget,
      );
    });
  });
}

class TestAuthController extends AuthController {
  TestAuthController(this._user);

  final AppUser _user;

  @override
  Future<AppUser?> build() async {
    return _user;
  }
}
