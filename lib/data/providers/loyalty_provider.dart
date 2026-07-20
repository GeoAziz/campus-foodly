import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/loyalty.dart';
import '../repositories/loyalty_repository.dart';
import 'auth_provider.dart';

final loyaltyRepositoryProvider = Provider<LoyaltyRepository>(
  (ref) => buildLoyaltyRepository(),
);

final userLoyaltyProvider = FutureProvider<LoyaltyRecord?>((ref) async {
  final authState = ref.watch(authControllerProvider);
  final userId = authState.valueOrNull?.id;
  if (userId == null) return null;

  return ref
      .watch(loyaltyRepositoryProvider)
      .getLoyaltyRecord(userId);
});

class LoyaltyNotifier extends StateNotifier<AsyncValue<LoyaltyRecord?>> {
  LoyaltyNotifier(this._repository, this._userId)
      : super(const AsyncValue.loading()) {
    _loadLoyalty();
  }

  final LoyaltyRepository _repository;
  final String? _userId;

  Future<void> _loadLoyalty() async {
    if (_userId == null) {
      state = const AsyncValue.data(null);
      return;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getLoyaltyRecord(_userId!),
    );
  }

  Future<void> redeemPoints(int points) async {
    if (_userId == null) return;

    try {
      await _repository.redeemPoints(_userId!, points);
      await _loadLoyalty();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final userLoyaltyNotifierProvider =
    StateNotifierProvider<LoyaltyNotifier, AsyncValue<LoyaltyRecord?>>((ref) {
  final authState = ref.watch(authControllerProvider);
  final userId = authState.valueOrNull?.id;
  final repository = ref.watch(loyaltyRepositoryProvider);

  return LoyaltyNotifier(repository, userId);
});
