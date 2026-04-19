import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart';
import '../repositories/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => buildOrderRepository(),
);

class OrderController extends StateNotifier<AsyncValue<List<Order>>> {
  OrderController(this._repository) : super(const AsyncValue.data([]));

  final OrderRepository _repository;

  Future<void> loadForUser(String userId) async {
    state = const AsyncValue.loading();
    state =
        await AsyncValue.guard(() => _repository.fetchOrdersForUser(userId));
  }

  Future<void> addOrder(Order order) async {
    await _repository.saveOrder(order);
    final current = state.value ?? <Order>[];
    state = AsyncValue.data([...current, order]);
  }
}

final orderControllerProvider =
    StateNotifierProvider<OrderController, AsyncValue<List<Order>>>(
  (ref) => OrderController(ref.watch(orderRepositoryProvider)),
);
