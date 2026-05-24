import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Mock classes for Firebase testing
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {
  @override
  String get uid => 'test-user-123';

  @override
  String? get email => 'test@example.com';

  @override
  String? get displayName => 'Test User';
}

class MockUserCredential extends Mock implements UserCredential {
  @override
  User? get user => MockUser();
}

class MockAuthResult {
  final bool success;
  final String? error;

  MockAuthResult({required this.success, this.error});
}

/// Setup function for mock Firebase in tests
FirebaseFirestore createMockFirestore() {
  return MockFirebaseFirestore();
}

FirebaseAuth createMockAuth() {
  return MockFirebaseAuth();
}

/// Test utilities
class TestUserData {
  static Map<String, dynamic> createValidUser({
    String uid = 'test-user-123',
    String email = 'test@example.com',
    String role = 'user',
  }) {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'createdAt': DateTime.now().toIso8601String(),
      'firstName': 'Test',
      'lastName': 'User',
    };
  }

  static Map<String, dynamic> createValidOrder({
    String userId = 'test-user-123',
    String restaurantId = 'rest-123',
    String status = 'pending',
  }) {
    return {
      'userId': userId,
      'restaurantId': restaurantId,
      'status': status,
      'items': [
        {
          'menuItemId': 'item-1',
          'quantity': 2,
          'price': 10.99,
        }
      ],
      'totalPrice': 21.98,
      'tax': 2.20,
      'deliveryFee': 5.00,
      'createdAt': DateTime.now().toIso8601String(),
      'idempotencyKey': 'test-key-123',
      'deliveryAddress': '123 Test St',
    };
  }

  static Map<String, dynamic> createValidPayment({
    String userId = 'test-user-123',
    String orderId = 'order-123',
    double amount = 29.18,
    String status = 'pending',
  }) {
    return {
      'userId': userId,
      'orderId': orderId,
      'amount': amount,
      'status': status,
      'provider': 'stripe',
      'paymentId': 'pay-123',
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}

void main() {
  test('Mock Firebase setup works', () {
    final firestore = createMockFirestore();
    expect(firestore, isNotNull);

    final auth = createMockAuth();
    expect(auth, isNotNull);
  });

  test('Test user data is valid', () {
    final userData = TestUserData.createValidUser();
    expect(userData['uid'], 'test-user-123');
    expect(userData['role'], 'user');
  });

  test('Test order data is valid', () {
    final orderData = TestUserData.createValidOrder();
    expect(orderData['userId'], 'test-user-123');
    expect(orderData['status'], 'pending');
    expect(orderData['items'].length, 1);
  });

  test('Test payment data is valid', () {
    final paymentData = TestUserData.createValidPayment();
    expect(paymentData['amount'], 29.18);
    expect(paymentData['status'], 'pending');
  });
}
