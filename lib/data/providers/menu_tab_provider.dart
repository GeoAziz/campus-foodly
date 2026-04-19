import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/menu_tab.dart';
import '../repositories/menu_tab_repository.dart';

final menuTabRepositoryProvider = Provider<MenuTabRepository>(
  (ref) => buildMenuTabRepository(),
);

final menuTabsProvider =
    FutureProvider.family<List<MenuTabItem>, String>((ref, restaurantId) {
  return ref.watch(menuTabRepositoryProvider).fetchMenuTabs(restaurantId);
});