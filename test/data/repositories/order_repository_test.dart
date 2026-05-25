import 'package:flutter_test/flutter_test.dart';
import 'package:ordereats/data/repositories/order_repository.dart';
import 'package:ordereats/data/models/order.dart';

void main() {
  group('OrderRepository', () {
    late InMemoryOrderRepository repository;

    setUp(() {
      repository = InMemoryOrderRepository();
    });

    test('creates an empty order list initially', () {
      expect(repository.fetchOrdersForUser('user-123'), completion(isEmpty));
    });

    test('saves and retrieves orders', () async {
      final order = Order(
        id: 'order-1',
        userId: 'user-123',
        restaurantId: 'rest-1',
        items: [],
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await repository.saveOrder(order);
      final orders = await repository.fetchOrdersForUser('user-123');

      expect(orders.length, 1);
      expect(orders[0].id, 'order-1');
    });

    test('filters orders by user ID', () async {
      final order1 = Order(
        id: 'order-1',
        userId: 'user-123',
        restaurantId: 'rest-1',
        items: [],
        status: 'pending',
        createdAt: DateTime.now(),
      );

      final order2 = Order(
        id: 'order-2',
        userId: 'user-456',
        restaurantId: 'rest-1',
        items: [],
        status: 'delivered',
        createdAt: DateTime.now(),
      );

      await repository.saveOrder(order1);
      await repository.saveOrder(order2);

      final userOrders = await repository.fetchOrdersForUser('user-123');
      expect(userOrders.length, 1);
      expect(userOrders[0].userId, 'user-123');
    });

    test('handles pagination', () async {
      for (int i = 0; i < 25; i++) {
        final order = Order(
          id: 'order-$i',
          userId: 'user-123',
          restaurantId: 'rest-1',
          items: [],
          status: 'pending',
          createdAt: DateTime.now(),
        );
        await repository.saveOrder(order);
      }

      final params = OrderPaginationParams(pageSize: 10);
      final result =
          await repository.fetchOrdersForUserPaginated('user-123', params);

      expect(result.orders.length, 10);
      expect(result.hasMore, false); // In-memory repo returns all
    });

    test('updates order status', () async {
      final order = Order(
        id: 'order-1',
        userId: 'user-123',
        restaurantId: 'rest-1',
        items: [],
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await repository.saveOrder(order);
      await repository.updateOrderStatus('order-1', 'accepted');

      final orders = await repository.fetchOrdersForUser('user-123');
      expect(orders[0].status, 'accepted');
    });

    test('retrieves order by ID', () async {
      final order = Order(
        id: 'order-1',
        userId: 'user-123',
        restaurantId: 'rest-1',
        items: [],
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await repository.saveOrder(order);
      final retrieved = await repository.fetchOrderById('order-1');

      expect(retrieved, isNotNull);
      expect(retrieved?.id, 'order-1');
    });

    test('retrieves orders by status', () async {
      final order1 = Order(
        id: 'order-1',
        userId: 'user-123',
        restaurantId: 'rest-1',
        items: [],
        status: 'pending',
        createdAt: DateTime.now(),
      );

      final order2 = Order(
        id: 'order-2',
        userId: 'user-123',
        restaurantId: 'rest-1',
        items: [],
        status: 'delivered',
        createdAt: DateTime.now(),
      );

      await repository.saveOrder(order1);
      await repository.saveOrder(order2);

      final pendingOrders = await repository.fetchOrdersByStatus('pending');
      expect(pendingOrders.length, 1);
      expect(pendingOrders[0].status, 'pending');
    });
  });
}
