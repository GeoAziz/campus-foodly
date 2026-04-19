import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/menu_item.dart';
import '../repositories/menu_repository.dart';

final menuRepositoryProvider = Provider<MenuRepository>(
  (ref) => buildMenuRepository(),
);

final menuItemsProvider =
    FutureProvider.family<List<MenuItem>, String>((ref, restaurantId) {
  return ref.watch(menuRepositoryProvider).fetchMenuItems(restaurantId);
});
