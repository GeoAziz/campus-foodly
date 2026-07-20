import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/restaurant.dart';
import '../services/mock_data_service.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';

abstract class RestaurantRepository {
  Future<List<Restaurant>> fetchRestaurants({String? campusId});

  /// Fetch restaurants with pagination support
  Future<List<Restaurant>> fetchRestaurantsPage({
    required int pageNumber,
    required int pageSize,
    String? campusId,
  });
}

class FirestoreRestaurantRepository implements RestaurantRepository {
  FirestoreRestaurantRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<List<Restaurant>> fetchRestaurants({String? campusId}) async {
    Query<Map<String, dynamic>> query = _firestore.collection('restaurants');

    if (campusId != null) {
      query = query.where('campusId', isEqualTo: campusId);
    }

    final snapshot = await query.get();

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

  @override
  Future<List<Restaurant>> fetchRestaurantsPage({
    required int pageNumber,
    required int pageSize,
    String? campusId,
  }) async {
    // Firestore pagination: fetch all sorted, then slice locally
    // This is a limitation of Firestore's API which doesn't support offset natively
    Query<Map<String, dynamic>> query = _firestore
        .collection('restaurants')
        .orderBy('name'); // Consistent ordering for pagination

    if (campusId != null) {
      query = query.where('campusId', isEqualTo: campusId);
    }

    final snapshot = await query.get();

    final allRestaurants = snapshot.docs
        .map((doc) => Restaurant.fromMap(doc.id, doc.data()))
        .toList(growable: false);

    final offset = pageNumber * pageSize;
    final end = (offset + pageSize).clamp(0, allRestaurants.length);

    if (offset >= allRestaurants.length) {
      return [];
    }

    final paginatedRestaurants = allRestaurants.sublist(offset, end);

    final storage = StorageService.instance;
    return Future.wait(
      paginatedRestaurants.map((restaurant) async {
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
  Future<List<Restaurant>> fetchRestaurants({String? campusId}) async {
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

  @override
  Future<List<Restaurant>> fetchRestaurantsPage({
    required int pageNumber,
    required int pageSize,
    String? campusId,
  }) async {
    final allRestaurants = await fetchRestaurants(campusId: campusId);
    final offset = pageNumber * pageSize;
    final end = (offset + pageSize).clamp(0, allRestaurants.length);

    if (offset >= allRestaurants.length) {
      return [];
    }

    return allRestaurants.sublist(offset, end);
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
