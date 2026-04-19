import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/menu_tab.dart';
import '../services/firebase_service.dart';

abstract class MenuTabRepository {
  Future<List<MenuTabItem>> fetchMenuTabs(String restaurantId);
}

class FirestoreMenuTabRepository implements MenuTabRepository {
  FirestoreMenuTabRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<List<MenuTabItem>> fetchMenuTabs(String restaurantId) async {
    final scopedSnapshot = await _firestore
        .collection('menu_tabs')
        .where('restaurantId', isEqualTo: restaurantId)
        .get();

    final scopedTabs = scopedSnapshot.docs
        .map((doc) => MenuTabItem.fromMap(doc.id, doc.data()))
        .toList(growable: false);

    scopedTabs.sort((a, b) => a.position.compareTo(b.position));
    return scopedTabs;
  }
}

class MockMenuTabRepository implements MenuTabRepository {
  @override
  Future<List<MenuTabItem>> fetchMenuTabs(String restaurantId) async {
    return const [
      MenuTabItem(
        id: 'tab-0',
        restaurantId: '',
        title: 'Most Populars',
        position: 0,
      ),
      MenuTabItem(
        id: 'tab-1',
        restaurantId: '',
        title: 'Beef & Lamb',
        position: 1,
      ),
      MenuTabItem(
        id: 'tab-2',
        restaurantId: '',
        title: 'Seafood',
        position: 2,
      ),
      MenuTabItem(
        id: 'tab-3',
        restaurantId: '',
        title: 'Appetizers',
        position: 3,
      ),
      MenuTabItem(
        id: 'tab-4',
        restaurantId: '',
        title: 'Dim Sum',
        position: 4,
      ),
    ];
  }
}

MenuTabRepository buildMenuTabRepository() {
  if (!FirebaseService.isInitialized) {
    return MockMenuTabRepository();
  }

  return FirestoreMenuTabRepository(FirebaseFirestore.instance);
}
