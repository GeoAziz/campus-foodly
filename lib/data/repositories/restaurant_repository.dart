import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/restaurant.dart';
import '../services/mock_data_service.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';

abstract class RestaurantRepository {
  Future<List<Restaurant>> fetchRestaurants();
}

class FirestoreRestaurantRepository implements RestaurantRepository {
  FirestoreRestaurantRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<List<Restaurant>> fetchRestaurants() async {
    final snapshot = await _firestore.collection('restaurants').get();

    final restaurants = snapshot.docs
        .map((doc) => Restaurant.fromMap(doc.id, doc.data()))
        .toList(growable: false);

    final storage = StorageService.instance;
    return Future.wait(
      restaurants.map((restaurant) async {
        final resolvedImage =
            await storage.resolveDownloadUrl(restaurant.image);
        return Restaurant(
          id: restaurant.id,
          name: restaurant.name,
          image: resolvedImage,
          location: restaurant.location,
          rating: restaurant.rating,
          ratingCount: restaurant.ratingCount,
          deliveryTime: restaurant.deliveryTime,
          deliveryFee: restaurant.deliveryFee,
          priceTier: restaurant.priceTier,
          categories: restaurant.categories,
          dietaries: restaurant.dietaries,
          isFeatured: restaurant.isFeatured,
        );
      }),
    );
  }
}

class MockRestaurantRepository implements RestaurantRepository {
  @override
  Future<List<Restaurant>> fetchRestaurants() async {
    return demoMediumCardData
        .asMap()
        .entries
        .map(
          (entry) => Restaurant(
            id: 'restaurant-${entry.key}',
            name: entry.value['name'] as String,
            image: entry.value['image'] as String,
            location: entry.value['location'] as String? ?? 'San Francisco',
            rating: (entry.value['rating'] as num).toDouble(),
            ratingCount: (entry.value['ratingCount'] as num? ?? 200).toInt(),
            deliveryTime: entry.value['deliveryTime'] as int,
            deliveryFee: entry.value['deliveryFee'] as String? ?? 'Free',
            categories:
                (entry.value['categories'] as List<dynamic>? ?? const [])
                    .map((item) => item.toString())
                    .toList(growable: false),
            dietaries: (entry.value['dietaries'] as List<dynamic>? ?? const [])
                .map((item) => item.toString())
                .toList(growable: false),
            priceTier: entry.value['priceTier'] as int? ?? 3,
            isFeatured: entry.key < 3,
          ),
        )
        .toList(growable: false);
  }
}

RestaurantRepository buildRestaurantRepository() {
  if (!FirebaseService.isInitialized) {
    throw StateError(
      'Firebase is not initialized. Configure Firebase before using restaurants.',
    );
  }

  return FirestoreRestaurantRepository(FirebaseFirestore.instance);
}
