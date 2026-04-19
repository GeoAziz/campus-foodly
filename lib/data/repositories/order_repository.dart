import 'package:cloud_firestore/cloud_firestore.dart' as firebase hide Order;

import '../models/order.dart';
import '../services/firebase_service.dart';

abstract class OrderRepository {
  Future<List<Order>> fetchOrdersForUser(String userId);
  Future<void> saveOrder(Order order);
}

class FirestoreOrderRepository implements OrderRepository {
  FirestoreOrderRepository(this._firestore);

  final firebase.FirebaseFirestore _firestore;

  @override
  Future<List<Order>> fetchOrdersForUser(String userId) async {
    final snapshot = await _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((doc) => Order.fromMap(doc.id, doc.data()))
        .toList(growable: false);
  }

  @override
  Future<void> saveOrder(Order order) async {
    await _firestore.collection('orders').doc(order.id).set(order.toMap());
  }
}

class InMemoryOrderRepository implements OrderRepository {
  final List<Order> _orders = [];

  @override
  Future<List<Order>> fetchOrdersForUser(String userId) async {
    return _orders.where((order) => order.userId == userId).toList();
  }

  @override
  Future<void> saveOrder(Order order) async {
    _orders.add(order);
  }
}

OrderRepository buildOrderRepository() {
  if (!FirebaseService.isInitialized) {
    throw StateError(
      'Firebase is not initialized. Configure Firebase before using orders.',
    );
  }

  return FirestoreOrderRepository(firebase.FirebaseFirestore.instance);
}
