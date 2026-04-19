import 'package:riverpod/riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/payment_method.dart';
import '../repositories/profile_repository.dart';
import 'profile_provider.dart';

class PaymentMethodsState {
  const PaymentMethodsState({
    this.methods = const [],
    this.isLoading = false,
    this.error,
    this.selectedMethodId,
  });

  final List<PaymentMethod> methods;
  final bool isLoading;
  final String? error;
  final String? selectedMethodId;

  PaymentMethodsState copyWith({
    List<PaymentMethod>? methods,
    bool? isLoading,
    String? error,
    String? selectedMethodId,
  }) {
    return PaymentMethodsState(
      methods: methods ?? this.methods,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedMethodId: selectedMethodId ?? this.selectedMethodId,
    );
  }

  PaymentMethod? get selectedMethod {
    if (selectedMethodId == null) return null;
    try {
      return methods.firstWhere((method) => method.id == selectedMethodId);
    } catch (e) {
      return null;
    }
  }

  PaymentMethod? get defaultMethod {
    try {
      return methods.firstWhere((method) => method.isDefault);
    } catch (e) {
      return null;
    }
  }
}

class PaymentMethodsController extends StateNotifier<PaymentMethodsState> {
  PaymentMethodsController(this._repository, this._uid)
      : super(const PaymentMethodsState()) {
    _loadPaymentMethods();
  }

  final ProfileRepository _repository;
  final String _uid;

  Future<void> _loadPaymentMethods() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final methods = await _repository.getPaymentMethods(_uid);
      state = state.copyWith(
        isLoading: false,
        methods: methods,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> addPaymentMethod(PaymentMethod method) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _repository.addPaymentMethod(_uid, method);
      state = state.copyWith(
        isLoading: false,
        methods: [...state.methods, method],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> updatePaymentMethod(PaymentMethod method) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _repository.updatePaymentMethod(_uid, method);

      final updatedMethods =
          state.methods.map((m) => m.id == method.id ? method : m).toList();

      state = state.copyWith(
        isLoading: false,
        methods: updatedMethods,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> deletePaymentMethod(String methodId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _repository.deletePaymentMethod(_uid, methodId);

      state = state.copyWith(
        isLoading: false,
        methods: state.methods.where((m) => m.id != methodId).toList(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> setDefaultPaymentMethod(String methodId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final updatedMethods = state.methods.map((method) {
        if (method.id == methodId) {
          return method.copyWith(isDefault: true);
        }
        return method.copyWith(isDefault: false);
      }).toList();

      for (final method in updatedMethods) {
        await _repository.updatePaymentMethod(_uid, method);
      }

      state = state.copyWith(
        isLoading: false,
        methods: updatedMethods,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void selectPaymentMethod(String methodId) {
    state = state.copyWith(selectedMethodId: methodId);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final paymentMethodsControllerProvider = StateNotifierProvider.family<
    PaymentMethodsController, PaymentMethodsState, String>((ref, uid) {
  final repository = ref.watch(profileRepositoryProvider);
  return PaymentMethodsController(repository, uid);
});

// Helper to create a new payment method
PaymentMethod createNewPaymentMethod({
  required String type,
  required String label,
  String? last4,
  String? brand,
  int? expiryMonth,
  int? expiryYear,
  String? tokenId,
}) {
  return PaymentMethod(
    id: const Uuid().v4(),
    type: type,
    label: label,
    last4: last4,
    brand: brand,
    expiryMonth: expiryMonth,
    expiryYear: expiryYear,
    tokenId: tokenId,
  );
}
