import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/featured_item.dart';
import '../services/firebase_service.dart';

abstract class FeaturedItemRepository {
  Future<List<FeaturedItem>> fetchFeaturedItems(String restaurantId);
}

class FirestoreFeaturedItemRepository implements FeaturedItemRepository {
  FirestoreFeaturedItemRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<List<FeaturedItem>> fetchFeaturedItems(String restaurantId) async {
    final scopedSnapshot = await _firestore
        .collection('featured_items')
        .where('restaurantId', isEqualTo: restaurantId)
        .get();

    final scopedItems = scopedSnapshot.docs
        .map((doc) => FeaturedItem.fromMap(doc.id, doc.data()))
        .toList(growable: false);

    scopedItems.sort((a, b) => a.position.compareTo(b.position));
    return scopedItems;
  }
}

class MockFeaturedItemRepository implements FeaturedItemRepository {
  @override
  Future<List<FeaturedItem>> fetchFeaturedItems(String restaurantId) async {
    return List.generate(
      3,
      (index) => FeaturedItem(
        id: 'featured-$restaurantId-$index',
        restaurantId: restaurantId,
        title: 'Cookie Sandwich',
        image: 'assets/images/featured_items_${index + 1}.png',
        foodType: 'Chinese',
        priceRange: r'$$',
        position: index,
      ),
    );
  }
}

FeaturedItemRepository buildFeaturedItemRepository() {
  if (!FirebaseService.isInitialized) {
    return MockFeaturedItemRepository();
  }

  return FirestoreFeaturedItemRepository(FirebaseFirestore.instance);
}
