import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/menu_item.dart';
import '../services/firebase_service.dart';

abstract class MenuRepository {
  Future<List<MenuItem>> fetchMenuItems(String restaurantId);
}

class FirestoreMenuRepository implements MenuRepository {
  FirestoreMenuRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<List<MenuItem>> fetchMenuItems(String restaurantId) async {
    final scopedSnapshot = await _firestore
        .collection('menu_items')
        .where('restaurantId', isEqualTo: restaurantId)
        .get();

    final scopedItems = scopedSnapshot.docs
        .map((doc) => MenuItem.fromMap(doc.id, doc.data()))
        .toList(growable: false);

    scopedItems.sort((a, b) => a.name.compareTo(b.name));
    return scopedItems;
  }
}

class MockMenuRepository implements MenuRepository {
  @override
  Future<List<MenuItem>> fetchMenuItems(String restaurantId) async {
    return [
      MenuItem(
        id: 'menu-$restaurantId-1',
        restaurantId: restaurantId,
        name: 'Signature Burger',
        price: 12.5,
        image: 'assets/images/big_1.png',
        description: 'Juicy beef burger with house sauce.',
        category: 'Burger',
      ),
      MenuItem(
        id: 'menu-$restaurantId-2',
        restaurantId: restaurantId,
        name: 'Loaded Fries',
        price: 6.0,
        image: 'assets/images/big_2.png',
        description: 'Crispy fries with cheese and herbs.',
        category: 'Sides',
      ),
      MenuItem(
        id: 'menu-$restaurantId-3',
        restaurantId: restaurantId,
        name: 'Chocolate Shake',
        price: 4.75,
        image: 'assets/images/big_3.png',
        description: 'Creamy dessert shake.',
        category: 'Drinks',
      ),
    ];
  }
}

MenuRepository buildMenuRepository() {
  if (!FirebaseService.isInitialized) {
    return MockMenuRepository();
  }

  return FirestoreMenuRepository(FirebaseFirestore.instance);
}
