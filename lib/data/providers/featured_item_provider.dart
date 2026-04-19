import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/featured_item.dart';
import '../repositories/featured_item_repository.dart';

final featuredItemRepositoryProvider = Provider<FeaturedItemRepository>(
  (ref) => buildFeaturedItemRepository(),
);

final featuredItemsProvider =
    FutureProvider.family<List<FeaturedItem>, String>((ref, restaurantId) {
  return ref
      .watch(featuredItemRepositoryProvider)
      .fetchFeaturedItems(restaurantId);
});