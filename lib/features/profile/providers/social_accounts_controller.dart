import 'package:riverpod/riverpod.dart';

import '../models/social_account.dart';
import '../repositories/profile_repository.dart';
import 'profile_provider.dart';

class SocialAccountsState {
  const SocialAccountsState({
    this.accounts = const [],
    this.isLoading = false,
    this.error,
    this.success = false,
  });

  final List<SocialAccount> accounts;
  final bool isLoading;
  final String? error;
  final bool success;

  SocialAccountsState copyWith({
    List<SocialAccount>? accounts,
    bool? isLoading,
    String? error,
    bool? success,
  }) {
    return SocialAccountsState(
      accounts: accounts ?? this.accounts,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      success: success ?? this.success,
    );
  }

  bool isProviderLinked(String provider) {
    return accounts.any((account) => account.provider == provider);
  }

  SocialAccount? getLinkedAccount(String provider) {
    try {
      return accounts.firstWhere((account) => account.provider == provider);
    } catch (e) {
      return null;
    }
  }
}

class SocialAccountsController extends StateNotifier<SocialAccountsState> {
  SocialAccountsController(this._repository, this._uid)
      : super(const SocialAccountsState()) {
    _loadAccounts();
  }

  final ProfileRepository _repository;
  final String _uid;

  Future<void> _loadAccounts() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final accounts = await _repository.getSocialAccounts(_uid);
      state = state.copyWith(
        isLoading: false,
        accounts: accounts,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> linkAccount(String provider, SocialAccount account) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _repository.linkSocialAccount(_uid, account);
      state = state.copyWith(
        isLoading: false,
        accounts: [...state.accounts, account],
        success: true,
      );

      // Clear success flag after a moment
      await Future.delayed(const Duration(seconds: 2));
      state = state.copyWith(success: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> unlinkAccount(String provider) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _repository.unlinkSocialAccount(_uid, provider);
      state = state.copyWith(
        isLoading: false,
        accounts: state.accounts
            .where((account) => account.provider != provider)
            .toList(),
        success: true,
      );

      // Clear success flag after a moment
      await Future.delayed(const Duration(seconds: 2));
      state = state.copyWith(success: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final socialAccountsControllerProvider = StateNotifierProvider.family<
    SocialAccountsController, SocialAccountsState, String>((ref, uid) {
  final repository = ref.watch(profileRepositoryProvider);
  return SocialAccountsController(repository, uid);
});
