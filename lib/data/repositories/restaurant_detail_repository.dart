import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/restaurant_detail.dart';
import '../services/firebase_service.dart';

abstract class RestaurantDetailRepository {
  Future<RestaurantDetail?> fetchRestaurantDetail(String restaurantId);
}

class FirestoreRestaurantDetailRepository
    implements RestaurantDetailRepository {
  FirestoreRestaurantDetailRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<RestaurantDetail?> fetchRestaurantDetail(String restaurantId) async {
    final scopedSnapshot = await _firestore
        .collection('restaurant_details')
        .where('restaurantId', isEqualTo: restaurantId)
        .limit(1)
        .get();

    if (scopedSnapshot.docs.isNotEmpty) {
      final doc = scopedSnapshot.docs.first;
      return RestaurantDetail.fromMap(doc.id, doc.data());
    }

    return null;
  }
}

class MockRestaurantDetailRepository implements RestaurantDetailRepository {
  @override
  Future<RestaurantDetail?> fetchRestaurantDetail(String restaurantId) async {
    return RestaurantDetail(
      id: 'detail-$restaurantId',
      restaurantId: restaurantId,
      foodTypes: const ['Chinese', 'American', 'Deshi food'],
      ratingCount: 200,
      deliveryFee: 'Free',
      deliveryTime: 25,
      takeAwayLabel: 'Take away',
    );
  }
}

RestaurantDetailRepository buildRestaurantDetailRepository() {
  if (!FirebaseService.isInitialized) {
    return MockRestaurantDetailRepository();
  }

  return FirestoreRestaurantDetailRepository(FirebaseFirestore.instance);
}
